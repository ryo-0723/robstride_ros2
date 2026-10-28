#include <gtest/gtest.h>

#include <atomic>
#include <chrono>
#include <cmath>
#include <cstring>
#include <future>
#include <limits>
#include <memory>
#include <rclcpp/rclcpp.hpp>
#include <thread>

#include "robstride_driver/driver.hpp"

namespace rs = robstride_driver;
using namespace std::chrono_literals;

namespace
{
constexpr double kPi = 3.14159265358979323846;
constexpr rs::Limits kLimits{-4 * kPi, 4 * kPi, -50, 50, -6, 6, -6, 6, 500, 5};

class PositionFeedback : public ::testing::Test
{
protected:
  void SetUp() override
  {
    static std::atomic<unsigned int> sequence{0};
    const auto suffix = std::to_string(sequence.fetch_add(1));
    context_ = std::make_shared<rclcpp::Context>();
    context_->init(0, nullptr);
    peer_ = std::make_shared<rclcpp::Node>("position_peer_" + suffix,
                                           rclcpp::NodeOptions().context(context_));
    config_.settings.transport.context = context_;
    config_.settings.transport.node_name = "position_driver_" + suffix;
    config_.settings.transport.transmit_topic = "/position_test_" + suffix + "/tx";
    config_.settings.transport.receive_topic = "/position_test_" + suffix + "/rx";
    config_.settings.clear_faults_on_start = false;
    config_.settings.feedback_timeout = 2s;
    config_.settings.stop_repetitions = 1;
    config_.settings.stop_interval = 0ms;
    rs::JointData joint;
    joint.name = "joint";
    joint.can_id = 1;
    joint.can_timeout_ticks = 4000;
    joint.limits = kLimits;
    joint.command_limits = {-4 * kPi, 4 * kPi, -50, 50, -6, 6};
    joint.kp = 30;
    joint.kd = 1;
    config_.joints.push_back(joint);
    publisher_ = peer_->create_publisher<can_msgs::msg::Frame>(
        config_.settings.transport.receive_topic, rclcpp::QoS(100).reliable());
    subscription_ = peer_->create_subscription<can_msgs::msg::Frame>(
        config_.settings.transport.transmit_topic, rclcpp::QoS(100).reliable(),
        [this](can_msgs::msg::Frame::ConstSharedPtr frame)
        {
          if ((frame->id & 255) != 1) {return;}
          const auto type = (frame->id >> 24) & 31;
          if (type == 6)
          {
            ++motor_zero_count_;
            if (zero_delay_reads_ == 0) {raw_ = 0.0; internal_offset_ = 0.0;}
            else {pending_zero_reads_ = zero_delay_reads_.load();}
          }
          if (type == 17)
          {
            can_msgs::msg::Frame reply;
            reply.id = (17u << 24) | (1u << 8) | 253u;
            reply.is_extended = true;
            reply.dlc = 8;
            reply.data = frame->data;
            const auto index = reply.data[0] | (reply.data[1] << 8);
            uint32_t value = index == rs::kIndexCanTimeout ? 4000u : 0u;
            if (index == rs::kIndexMechanicalPosition)
            {
              if (pending_zero_reads_ > 0 && --pending_zero_reads_ == 0) {
                raw_ = 0.0; internal_offset_ = 0.0;
              }
              const float internal = static_cast<float>(raw_.load() + internal_offset_.load());
              std::memcpy(&value, &internal, sizeof(value));
            }
            for (int byte = 0; byte < 4; ++byte)
            {
              reply.data[4 + byte] = static_cast<uint8_t>(value >> (8 * byte));
            }
            publisher_->publish(reply);
          }
          else if (type == 1 || type == 3 || type == 4)
          {
            if (type == 3) {
              mode_ = rs::kMotorModeRun; ++enable_count_;
              if (switch_view_on_enable_) {
                switch_view_on_enable_ = false;
                publish_feedback();  // An early Run frame can still use the boot representation.
                view_timer_ = peer_->create_wall_timer(10ms, [this]() {
                  raw_ = raw_.load() + 2 * kPi;
                  internal_offset_ = internal_offset_.load() - 2 * kPi;
                  publish_feedback();
                  view_timer_->cancel();
                });
                return;
              }
              if (drop_enable_reply_) {return;}
            }
            if (type == 4) { mode_ = rs::kMotorModeReset; }
            if (type == 1)
            {
              last_position_command_ = rs::decode_u16((frame->data[0] << 8) | frame->data[1],
                                                      kLimits.position_min, kLimits.position_max);
              last_kp_ = rs::decode_u16((frame->data[4] << 8) | frame->data[5], 0, kLimits.kp_max);
              ++motion_count_;
            }
            publish_feedback();
          }
        });
    rclcpp::ExecutorOptions options;
    options.context = context_;
    executor_ = std::make_unique<rclcpp::executors::SingleThreadedExecutor>(options);
    executor_->add_node(peer_);
    worker_ = std::thread([this]() { executor_->spin(); });
  }

  void TearDown() override
  {
    driver_.reset();
    executor_->cancel();
    if (worker_.joinable()) {worker_.join();}
    executor_.reset();
    subscription_.reset();
    publisher_.reset();
    peer_.reset();
    context_->shutdown("position feedback test complete");
  }

  template <typename Predicate>
  bool wait_until(Predicate predicate)
  {
    const auto deadline = std::chrono::steady_clock::now() + 5s;
    do {
      if (predicate()) { return true; }
      std::this_thread::sleep_for(2ms);
    } while (std::chrono::steady_clock::now() < deadline);
    return predicate();
  }

  bool start(rs::PositionRestartPolicy policy = rs::PositionRestartPolicy::restore)
  {
    config_.joints[0].position_recovery = policy;
    driver_ = std::make_unique<rs::RobStrideDriver>(rclcpp::get_logger("position_test"));
    return driver_->initialize(config_) && driver_->open() && driver_->start();
  }

  void publish_feedback()
  {
    can_msgs::msg::Frame frame;
    frame.id = (2u << 24) | (static_cast<uint32_t>(mode_.load()) << 22) | (1u << 8) | 253u;
    frame.is_extended = true;
    frame.dlc = 8;
    const uint16_t values[] = {rs::encode_u16(raw_, kLimits.position_min, kLimits.position_max),
                               rs::encode_u16(0, -50, 50), rs::encode_u16(0, -6, 6), 250};
    for (int field = 0; field < 4; ++field)
    {
      frame.data[field * 2] = static_cast<uint8_t>(values[field] >> 8);
      frame.data[field * 2 + 1] = static_cast<uint8_t>(values[field]);
    }
    publisher_->publish(frame);
  }

  bool observe(double raw, double expected, uint8_t mode = rs::kMotorModeRun)
  {
    const auto before = driver_->metrics().motors[0].feedback_frames_received;
    raw_ = raw;
    mode_ = mode;
    publish_feedback();
    return wait_until(
        [&]()
        {
          const auto feedback = driver_->metrics().motors[0];
          if (feedback.feedback_frames_received <= before || feedback.mode != mode)
          {
            return false;
          }
          return driver_->update_state() &&
                 std::abs(driver_->joints()[0].state.position - expected) < 0.002;
        });
  }

  rclcpp::Context::SharedPtr context_;
  rclcpp::Node::SharedPtr peer_;
  rclcpp::Publisher<can_msgs::msg::Frame>::SharedPtr publisher_;
  rclcpp::Subscription<can_msgs::msg::Frame>::SharedPtr subscription_;
  std::unique_ptr<rclcpp::executors::SingleThreadedExecutor> executor_;
  std::thread worker_;
  rs::DriverConfiguration config_;
  std::unique_ptr<rs::RobStrideDriver> driver_;
  std::atomic<unsigned> zero_delay_reads_{0};
  unsigned pending_zero_reads_{0};
  std::atomic<bool> switch_view_on_enable_{false};
  rclcpp::TimerBase::SharedPtr view_timer_;
  std::atomic<bool> drop_enable_reply_{false};
  std::atomic<unsigned> enable_count_{0};
  std::atomic<double> raw_{1.0};
  std::atomic<double> internal_offset_{0.0};
  std::atomic<uint8_t> mode_{rs::kMotorModeReset};
  std::atomic<double> last_position_command_{0.0};
  std::atomic<double> last_kp_{0.0};
  std::atomic<unsigned int> motion_count_{0};
  std::atomic<unsigned int> motor_zero_count_{0};
};

TEST_F(PositionFeedback, PublishesContinuousAngleAcrossSeveralForwardAndReverseWraps)
{
  ASSERT_TRUE(start());
  for (int step = 10; step <= 700; step += 5)
  {
    const double q = step * 0.1;
    ASSERT_TRUE(observe(std::remainder(q, 8 * kPi), q));
  }
  for (int step = 700; step >= -700; step -= 5)
  {
    const double q = step * 0.1;
    ASSERT_TRUE(observe(std::remainder(q, 8 * kPi), q));
  }
}

TEST_F(PositionFeedback, RestoresAcrossUnexpectedResetAndTranslatesPositionTarget)
{
  ASSERT_TRUE(start());
  ASSERT_TRUE(observe(7.0, 7.0));
  ASSERT_TRUE(observe(7.0 - 2 * kPi, 7.0, rs::kMotorModeReset));
  ASSERT_TRUE(driver_->apply_command_modes({{true, false, false}}));
  ASSERT_TRUE(driver_->send_commands());  // Establish the initial current-position hold.
  driver_->joints()[0].command.position = 7.1;
  const auto before = motion_count_.load();
  ASSERT_TRUE(driver_->send_commands());
  ASSERT_TRUE(wait_until(
      [&]()
      { return driver_->update_state() && driver_->send_commands() && motion_count_ > before; }));
  EXPECT_NEAR(last_position_command_.load(), 7.1 - 2 * kPi, 0.002);
}

TEST_F(PositionFeedback, ResetPolicyRejectsOldPositionTargetUntilReactivation)
{
  ASSERT_TRUE(start(rs::PositionRestartPolicy::reset));
  ASSERT_TRUE(observe(7.0, 7.0));
  ASSERT_TRUE(driver_->apply_command_modes({{true, false, false}}));
  ASSERT_TRUE(observe(1.0, 1.0, rs::kMotorModeReset));
  EXPECT_TRUE(driver_->send_commands());  // Neutral while upper controller must reactivate.
  ASSERT_TRUE(driver_->apply_command_modes({{false, false, false}}));
  driver_->stop();
  ASSERT_TRUE(driver_->start());
  ASSERT_TRUE(driver_->apply_command_modes({{true, false, false}}));
  EXPECT_NEAR(driver_->joints()[0].command.position, 1.0, 0.002);
  EXPECT_TRUE(driver_->send_commands());
}

TEST_F(PositionFeedback, RestoresAfterFeedbackGapEvenWhenFirstResponseIsRun)
{
  ASSERT_TRUE(start());
  ASSERT_TRUE(observe(7.0, 7.0));
  // At 50 rad/s, 300 ms exceeds half of the feedback period. The missing
  // trajectory is unknown, so the configured restart policy must be applied.
  std::this_thread::sleep_for(300ms);
  ASSERT_TRUE(observe(7.0 - 2 * kPi, 7.0));
}

TEST_F(PositionFeedback, ZeroServiceRebasesJointAndPreservesPhysicalTargets)
{
  ASSERT_TRUE(start());
  ASSERT_TRUE(observe(2.0, 2.0));
  const double before = driver_->joints()[0].state.position;
  const auto limits = driver_->joints()[0].command_limits;
  auto client = peer_->create_client<std_srvs::srv::Trigger>(
      "/" + config_.settings.transport.node_name + "/zero_position_1");
  ASSERT_TRUE(client->wait_for_service(3s));
  auto result = client->async_send_request(std::make_shared<std_srvs::srv::Trigger::Request>());
  ASSERT_EQ(result.wait_for(3s), std::future_status::ready);
  ASSERT_TRUE(result.get()->success);
  ASSERT_TRUE(driver_->update_state());
  EXPECT_NEAR(driver_->joints()[0].state.position, 0.0, 1e-12);
  EXPECT_NEAR(driver_->joints()[0].command_limits.position_min, limits.position_min - before,
              1e-12);
  EXPECT_NEAR(driver_->joints()[0].command_limits.position_max, limits.position_max - before,
              1e-12);
  EXPECT_DOUBLE_EQ(raw_.load(), 2.0);
  EXPECT_EQ(motor_zero_count_, 0u);
  ASSERT_TRUE(observe(2.1, 0.1));
  ASSERT_TRUE(driver_->apply_command_modes({{true, false, false}}));
  ASSERT_TRUE(driver_->send_commands());  // Establish the initial current-position hold.
  driver_->joints()[0].command.position = 0.25;
  const auto count = motion_count_.load();
  ASSERT_TRUE(driver_->send_commands());
  ASSERT_TRUE(wait_until([&]() { return motion_count_ > count; }));
  EXPECT_NEAR(last_position_command_.load(), before + 0.25, 0.002);
}

TEST_F(PositionFeedback, ZeroServiceRejectsClaimedPositionWithoutChangingOrigin)
{
  ASSERT_TRUE(start());
  ASSERT_TRUE(observe(2.0, 2.0));
  ASSERT_TRUE(driver_->apply_command_modes({{true, false, false}}));
  const double offset = driver_->joints()[0].position_offset;
  auto client = peer_->create_client<std_srvs::srv::Trigger>(
      "/" + config_.settings.transport.node_name + "/zero_position_1");
  ASSERT_TRUE(client->wait_for_service(3s));
  auto result = client->async_send_request(std::make_shared<std_srvs::srv::Trigger::Request>());
  ASSERT_EQ(result.wait_for(3s), std::future_status::ready);
  EXPECT_FALSE(result.get()->success);
  EXPECT_DOUBLE_EQ(driver_->joints()[0].position_offset, offset);
  ASSERT_TRUE(driver_->update_state());
  EXPECT_NEAR(driver_->joints()[0].state.position, 2.0, 0.002);
  EXPECT_EQ(motor_zero_count_, 0u);
}

TEST_F(PositionFeedback, ZeroPositionRejectsStaleInactiveAndUnknownRequests)
{
  config_.settings.feedback_timeout = 20ms;
  ASSERT_TRUE(start());
  ASSERT_TRUE(observe(2.0, 2.0));
  std::this_thread::sleep_for(50ms);
  std::string error;
  EXPECT_FALSE(driver_->zero_current_position(0, &error));
  EXPECT_NE(error.find("Fresh"), std::string::npos);
  driver_->stop();
  EXPECT_FALSE(driver_->zero_current_position(0, &error));
  EXPECT_NE(error.find("active"), std::string::npos);
  EXPECT_FALSE(driver_->zero_current_position(100, &error));
  EXPECT_NE(error.find("Unknown"), std::string::npos);
}

TEST_F(PositionFeedback, ZeroPositionSupportsDirectionRatioOffsetAndRepeatedZeroing)
{
  auto & joint = config_.joints[0];
  joint.direction = -1.0;
  joint.gear_ratio = 2.0;
  joint.position_offset = 0.25;
  const auto range = joint.joint_position_range();
  ASSERT_TRUE(range);
  joint.command_limits.position_min = range->first;
  joint.command_limits.position_max = range->second;
  ASSERT_TRUE(start());
  ASSERT_TRUE(observe(4.0, -1.75));
  ASSERT_TRUE(driver_->apply_command_modes({{false, true, false}}));
  std::string error;
  ASSERT_TRUE(driver_->zero_current_position(0, &error)) << error;
  ASSERT_TRUE(driver_->update_state());
  EXPECT_NEAR(driver_->joints()[0].state.position, 0.0, 1e-12);
  ASSERT_TRUE(observe(4.6, -0.3));
  ASSERT_TRUE(driver_->zero_current_position(0, &error)) << error;
  ASSERT_TRUE(driver_->update_state());
  EXPECT_NEAR(driver_->joints()[0].state.position, 0.0, 1e-12);
  ASSERT_TRUE(driver_->apply_command_modes({{true, false, false}}));
  ASSERT_TRUE(driver_->send_commands());  // Establish the initial current-position hold.
  driver_->joints()[0].command.position = -0.2;
  const auto count = motion_count_.load();
  ASSERT_TRUE(driver_->send_commands());
  ASSERT_TRUE(wait_until([&]() { return motion_count_ > count; }));
  EXPECT_NEAR(last_position_command_.load(), 5.0, 0.002);
  EXPECT_EQ(motor_zero_count_, 0u);
}

TEST_F(PositionFeedback, ClosingDriverRemovesZeroService)
{
  ASSERT_TRUE(start());
  auto client = peer_->create_client<std_srvs::srv::Trigger>(
      "/" + config_.settings.transport.node_name + "/zero_position_1");
  ASSERT_TRUE(client->wait_for_service(3s));
  driver_->stop();
  driver_->close();
  ASSERT_TRUE(wait_until([&]() { return !client->service_is_ready(); }));
}
}  // namespace

TEST_F(PositionFeedback, OutOfRangeInternalPositionCanBeHomedAndReactivated)
{
  raw_ = -11.0;
  internal_offset_ = 8 * kPi;
  ASSERT_TRUE(start());
  ASSERT_FALSE(driver_->apply_command_modes({{true, false, false}}));
  auto call = [&](const std::string & name)
  {
    auto client = peer_->create_client<std_srvs::srv::Trigger>(
        "/" + config_.settings.transport.node_name + "/" + name + "_1");
    EXPECT_TRUE(client->wait_for_service(3s));
    auto result = client->async_send_request(std::make_shared<std_srvs::srv::Trigger::Request>());
    EXPECT_EQ(result.wait_for(3s), std::future_status::ready);
    return result.get()->success;
  };
  ASSERT_TRUE(call("begin_homing"));
  EXPECT_FALSE(driver_->apply_command_modes({{true, false, false}}));
  ASSERT_TRUE(driver_->apply_command_modes({{false, true, false}}));
  driver_->joints()[0].command.velocity = 0.2;
  ASSERT_TRUE(driver_->send_commands());
  EXPECT_FALSE(call("finish_homing"));  // Must release controller and stop first.
  ASSERT_TRUE(driver_->apply_command_modes({{false, false, false}}));
  zero_delay_reads_ = 3;  // Firmware may keep reporting its old angle briefly.
  ASSERT_TRUE(call("finish_homing"));
  EXPECT_FALSE(call("homing_ready"));
  EXPECT_FALSE(driver_->apply_command_modes({{false, true, false}}));
  ASSERT_TRUE(driver_->update_state());
  ASSERT_TRUE(call("homing_ready"));
  EXPECT_EQ(motor_zero_count_, 1u);
  EXPECT_NEAR(driver_->joints()[0].state.position, 0.0, 0.002);
  ASSERT_TRUE(driver_->apply_command_modes({{true, false, false}}));
  ASSERT_TRUE(driver_->send_commands());  // Establish the initial current-position hold.
  driver_->joints()[0].command.position = 1.0;  // Normal operation may target far from feedback.
  ASSERT_TRUE(driver_->send_commands());
}

TEST_F(PositionFeedback, InternalReferenceDoesNotModuloUnsafeHoldIntoAnotherTurn)
{
  raw_ = -11;
  internal_offset_ = 8 * kPi;
  ASSERT_TRUE(start());
  EXPECT_FALSE(driver_->joints()[0].checked_position_command(-11));
  EXPECT_FALSE(driver_->apply_command_modes({{true, false, false}}));
  EXPECT_TRUE(driver_->zero_current_position(0));
  EXPECT_FALSE(driver_->apply_command_modes({{true, false, false}}));
  EXPECT_EQ(motor_zero_count_, 0u);
}

TEST_F(PositionFeedback, HomingRejectsCommandsBeyondConfiguredSpeed)
{
  ASSERT_TRUE(start());
  auto client = peer_->create_client<std_srvs::srv::Trigger>(
      "/" + config_.settings.transport.node_name + "/begin_homing_1");
  ASSERT_TRUE(client->wait_for_service(3s));
  auto result = client->async_send_request(std::make_shared<std_srvs::srv::Trigger::Request>());
  ASSERT_EQ(result.wait_for(3s), std::future_status::ready);
  ASSERT_TRUE(result.get()->success);
  ASSERT_TRUE(driver_->apply_command_modes({{false, true, false}}));
  driver_->joints()[0].command.velocity = 0.6;
  EXPECT_FALSE(driver_->send_commands());
}

TEST_F(PositionFeedback, InvalidInternalReadingPreventsStartup)
{
  internal_offset_ = std::numeric_limits<double>::quiet_NaN();
  EXPECT_FALSE(start());
  EXPECT_DOUBLE_EQ(last_kp_, 0.0);
}

TEST_F(PositionFeedback, ResetWhilePositionClaimedNeedsExplicitReactivation)
{
  ASSERT_TRUE(start());
  ASSERT_TRUE(observe(7.0, 7.0));
  ASSERT_TRUE(driver_->apply_command_modes({{true, false, false}}));
  ASSERT_TRUE(driver_->send_commands());  // Establish the initial current-position hold.
  driver_->joints()[0].command.position = 7.1;
  ASSERT_TRUE(driver_->send_commands());
  ASSERT_TRUE(observe(7.0 - 2 * kPi, 7.0, rs::kMotorModeReset));
  const auto count = motion_count_.load();
  ASSERT_TRUE(driver_->send_commands());
  ASSERT_TRUE(wait_until([&]() { return motion_count_ > count; }));
  EXPECT_DOUBLE_EQ(last_kp_, 0.0);
  ASSERT_TRUE(driver_->apply_command_modes({{false, false, false}}));
  ASSERT_TRUE(driver_->apply_command_modes({{true, false, false}}));
  EXPECT_NEAR(driver_->joints()[0].command.position, 7.0, 0.002);
  EXPECT_TRUE(driver_->send_commands());
}

TEST_F(PositionFeedback, StartupTargetMismatchIsBlockedButLaterDistantTargetsAreAllowed)
{
  ASSERT_TRUE(start());
  ASSERT_TRUE(driver_->apply_command_modes({{true, false, false}}));
  driver_->joints()[0].command.position = 3.0;
  auto count = motion_count_.load();
  ASSERT_TRUE(driver_->send_commands());
  ASSERT_TRUE(wait_until([&]() {return motion_count_ > count;}));
  EXPECT_DOUBLE_EQ(last_kp_, 0.0);
  EXPECT_TRUE(driver_->joints()[0].position_reference_changed);
  ASSERT_TRUE(driver_->apply_command_modes({{false, false, false}}));
  ASSERT_TRUE(driver_->apply_command_modes({{true, false, false}}));
  ASSERT_TRUE(driver_->send_commands());
  driver_->joints()[0].command.position = 3.0;
  count = motion_count_.load();
  ASSERT_TRUE(driver_->send_commands());
  ASSERT_TRUE(wait_until([&]() {return motion_count_ > count;}));
  EXPECT_FALSE(driver_->joints()[0].position_reference_changed);
  EXPECT_GT(last_kp_, 0.0);
}

TEST_F(PositionFeedback, ZeroGainHeartbeatConfirmsRunWhenEnableReplyIsLost)
{
  drop_enable_reply_ = true;
  ASSERT_TRUE(start());
  EXPECT_EQ(enable_count_, 1u);
  EXPECT_DOUBLE_EQ(last_kp_, 0.0);
}

TEST_F(PositionFeedback, SlowSecondAxisReadKeepsFirstAxisReferenceFresh)
{
  auto second = config_.joints.front();
  second.name = "second_axis";
  second.can_id = 2;
  config_.joints.push_back(second);
  std::atomic<uint8_t> second_mode{rs::kMotorModeReset};
  bool pending = false;
  bool delayed = false;
  auto due = std::chrono::steady_clock::now();
  auto parameter_reply = [&](const can_msgs::msg::Frame & request) {
    can_msgs::msg::Frame reply = request;
    reply.id = (17u << 24) | (2u << 8) | 253u;
    const unsigned index = reply.data[0] | (reply.data[1] << 8);
    uint32_t bits = index == rs::kIndexCanTimeout ? 4000u : 0u;
    if (index == rs::kIndexMechanicalPosition) {
      const float position = 1.0f;
      std::memcpy(&bits, &position, sizeof(bits));
    }
    for (int i = 0; i < 4; ++i) {reply.data[4 + i] = static_cast<uint8_t>(bits >> (8 * i));}
    publisher_->publish(reply);
  };
  can_msgs::msg::Frame delayed_request;
  auto timer = peer_->create_wall_timer(5ms, [&]() {
    if (pending && std::chrono::steady_clock::now() >= due) {
      pending = false;
      parameter_reply(delayed_request);
    }
  });
  auto second_sub = peer_->create_subscription<can_msgs::msg::Frame>(
    config_.settings.transport.transmit_topic, rclcpp::QoS(100).reliable(),
    [&](can_msgs::msg::Frame::ConstSharedPtr frame) {
      if ((frame->id & 255) != 2) {return;}
      const auto type = (frame->id >> 24) & 31;
      if (type == 17) {
        const unsigned index = frame->data[0] | (frame->data[1] << 8);
        if (index == rs::kIndexMechanicalPosition && !delayed) {
          delayed = true; pending = true; delayed_request = *frame;
          due = std::chrono::steady_clock::now() + 350ms;
        } else {parameter_reply(*frame);}
      } else if (type == 1 || type == 3 || type == 4) {
        if (type == 3) {second_mode = rs::kMotorModeRun;}
        if (type == 4) {second_mode = rs::kMotorModeReset;}
        can_msgs::msg::Frame reply;
        reply.id = (2u << 24) | (static_cast<uint32_t>(second_mode.load()) << 22) | (2u << 8) | 253u;
        reply.is_extended = true; reply.dlc = 8;
        const uint16_t values[] = {rs::encode_u16(1, kLimits.position_min, kLimits.position_max),
          rs::encode_u16(0, -50, 50), rs::encode_u16(0, -6, 6), 250};
        for (int i = 0; i < 4; ++i) {
          reply.data[2 * i] = static_cast<uint8_t>(values[i] >> 8);
          reply.data[2 * i + 1] = static_cast<uint8_t>(values[i]);
        }
        publisher_->publish(reply);
      }
    });
  ASSERT_TRUE(start());
  EXPECT_TRUE(driver_->joints()[0].motor_reference_ready);
  EXPECT_TRUE(driver_->joints()[1].motor_reference_ready);
  EXPECT_TRUE(driver_->validate_command_modes({{true, false, false}, {true, false, false}}));
  driver_->stop();
  driver_->close();
  executor_->cancel();
  if (worker_.joinable()) {worker_.join();}
}

TEST_F(PositionFeedback, BootCoordinateRepresentationDoesNotAddAnExtraTurn)
{
  ASSERT_TRUE(start());
  ASSERT_TRUE(observe(12.143, 12.143));
  internal_offset_ = 2 * kPi;
  switch_view_on_enable_ = true;
  const double restored = -0.419 + 4 * kPi;
  ASSERT_TRUE(observe(-0.419, restored, rs::kMotorModeReset));
  EXPECT_NEAR(driver_->joints()[0].state.position, restored, 0.002);
  EXPECT_FALSE(driver_->joints()[0].position_recovery_in_progress);
  EXPECT_TRUE(driver_->joints()[0].motor_reference_ready);
  ASSERT_TRUE(driver_->apply_command_modes({{true, false, false}}));
  EXPECT_NEAR(*driver_->joints()[0].checked_position_command(
    driver_->joints()[0].command.position), -0.419 + 2 * kPi, 0.003);
}

TEST_F(PositionFeedback, StartupMechanicalZeroWaitsForReadbackAndPreservesRosOffset)
{
  config_.settings.set_zero_on_start = true;
  config_.joints[0].position_offset = 0.5;
  raw_ = 8.0;
  zero_delay_reads_ = 3;
  ASSERT_TRUE(start());
  EXPECT_EQ(motor_zero_count_, 1u);
  EXPECT_NEAR(driver_->joints()[0].state.position, 0.5, 0.002);
  EXPECT_DOUBLE_EQ(driver_->joints()[0].position_offset, 0.5);
  EXPECT_TRUE(driver_->apply_command_modes({{true, false, false}}));
}
