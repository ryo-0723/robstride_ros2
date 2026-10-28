#include <atomic>
#include <chrono>
#include <cmath>
#include <future>
#include <memory>
#include <thread>

#include <gtest/gtest.h>
#include <rclcpp/rclcpp.hpp>

#include "robstride_driver/driver.hpp"

namespace rs = robstride_driver;
using namespace std::chrono_literals;

namespace
{
constexpr double kPi = 3.14159265358979323846;
constexpr rs::Limits kLimits{
  -4 * kPi, 4 * kPi, -50, 50, -6, 6, -6, 6, 500, 5};

class PositionFeedback : public ::testing::Test
{
protected:
  void SetUp() override
  {
    static std::atomic<unsigned int> sequence{0};
    const auto suffix = std::to_string(sequence.fetch_add(1));
    context_ = std::make_shared<rclcpp::Context>();
    context_->init(0, nullptr);
    peer_ = std::make_shared<rclcpp::Node>(
      "position_peer_" + suffix, rclcpp::NodeOptions().context(context_));
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
      [this](can_msgs::msg::Frame::ConstSharedPtr frame) {
        const auto type = (frame->id >> 24) & 31;
        if (type == 6) {++motor_zero_count_;}
        if (type == 17) {
          can_msgs::msg::Frame reply;
          reply.id = (17u << 24) | (1u << 8) | 253u;
          reply.is_extended = true;
          reply.dlc = 8;
          reply.data = frame->data;
          const auto index = reply.data[0] | (reply.data[1] << 8);
          const uint32_t value = index == rs::kIndexCanTimeout ? 4000u : 0u;
          for (int byte = 0; byte < 4; ++byte) {
            reply.data[4 + byte] = static_cast<uint8_t>(value >> (8 * byte));
          }
          publisher_->publish(reply);
        } else if (type == 1 || type == 3 || type == 4) {
          if (type == 3) {mode_ = rs::kMotorModeRun;}
          if (type == 4) {mode_ = rs::kMotorModeReset;}
          if (type == 1) {
            last_position_command_ = rs::decode_u16(
              (frame->data[0] << 8) | frame->data[1], kLimits.position_min, kLimits.position_max);
            ++motion_count_;
          }
          publish_feedback();
        }
      });
    rclcpp::ExecutorOptions options;
    options.context = context_;
    executor_ = std::make_unique<rclcpp::executors::SingleThreadedExecutor>(options);
    executor_->add_node(peer_);
    worker_ = std::thread([this]() {executor_->spin();});
  }

  void TearDown() override
  {
    driver_.reset();
    executor_->cancel();
    worker_.join();
    executor_.reset();
    subscription_.reset();
    publisher_.reset();
    peer_.reset();
    context_->shutdown("position feedback test complete");
  }

  template<typename Predicate>
  bool wait_until(Predicate predicate)
  {
    const auto deadline = std::chrono::steady_clock::now() + 5s;
    do {
      if (predicate()) {return true;}
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
    const uint16_t values[] = {
      rs::encode_u16(raw_, kLimits.position_min, kLimits.position_max),
      rs::encode_u16(0, -50, 50), rs::encode_u16(0, -6, 6), 250};
    for (int field = 0; field < 4; ++field) {
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
    return wait_until([&]() {
      const auto feedback = driver_->metrics().motors[0];
      if (feedback.feedback_frames_received <= before || feedback.mode != mode) {return false;}
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
  std::atomic<double> raw_{1.0};
  std::atomic<uint8_t> mode_{rs::kMotorModeReset};
  std::atomic<double> last_position_command_{0.0};
  std::atomic<unsigned int> motion_count_{0};
  std::atomic<unsigned int> motor_zero_count_{0};
};

TEST_F(PositionFeedback, PublishesContinuousAngleAcrossSeveralForwardAndReverseWraps)
{
  ASSERT_TRUE(start());
  for (int step = 10; step <= 700; step += 5) {
    const double q = step * 0.1;
    ASSERT_TRUE(observe(std::remainder(q, 8 * kPi), q));
  }
  for (int step = 700; step >= -700; step -= 5) {
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
  driver_->joints()[0].command.position = 7.1;
  const auto before = motion_count_.load();
  ASSERT_TRUE(driver_->send_commands());
  ASSERT_TRUE(wait_until([&]() {
    return driver_->update_state() && driver_->send_commands() && motion_count_ > before;
  }));
  EXPECT_NEAR(last_position_command_.load(), 7.1 - 2 * kPi, 0.002);
}

TEST_F(PositionFeedback, ResetPolicyRejectsOldPositionTargetUntilReactivation)
{
  ASSERT_TRUE(start(rs::PositionRestartPolicy::reset));
  ASSERT_TRUE(observe(7.0, 7.0));
  ASSERT_TRUE(driver_->apply_command_modes({{true, false, false}}));
  ASSERT_TRUE(observe(1.0, 1.0, rs::kMotorModeReset));
  EXPECT_FALSE(driver_->send_commands());
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
  EXPECT_NEAR(driver_->joints()[0].command_limits.position_min, limits.position_min - before, 1e-12);
  EXPECT_NEAR(driver_->joints()[0].command_limits.position_max, limits.position_max - before, 1e-12);
  EXPECT_DOUBLE_EQ(raw_.load(), 2.0);
  EXPECT_EQ(motor_zero_count_, 0u);
  ASSERT_TRUE(observe(2.1, 0.1));
  ASSERT_TRUE(driver_->apply_command_modes({{true, false, false}}));
  driver_->joints()[0].command.position = 0.25;
  const auto count = motion_count_.load();
  ASSERT_TRUE(driver_->send_commands());
  ASSERT_TRUE(wait_until([&]() {return motion_count_ > count;}));
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
  driver_->joints()[0].command.position = -0.2;
  const auto count = motion_count_.load();
  ASSERT_TRUE(driver_->send_commands());
  ASSERT_TRUE(wait_until([&]() {return motion_count_ > count;}));
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
  ASSERT_TRUE(wait_until([&]() {return !client->service_is_ready();}));
}
}  // namespace
