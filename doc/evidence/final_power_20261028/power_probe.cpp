#include <chrono>
#include <cmath>
#include <cstring>
#include <future>
#include <iomanip>
#include <iostream>
#include <optional>
#include <stdexcept>
#include <thread>
#include <rclcpp/rclcpp.hpp>
#include "robstride_driver/driver.hpp"
#include "robstride_driver/motor_profile.hpp"
using namespace std::chrono_literals;
namespace rs = robstride_driver;
int main(int argc,char **argv){
 rclcpp::init(argc,argv);int result=1;
 try{
  auto peer=rclcpp::Node::make_shared("zero_live_reference");
  rclcpp::executors::SingleThreadedExecutor executor;executor.add_node(peer);
  auto tx=peer->create_publisher<can_msgs::msg::Frame>("/to_can_bus",100);
  std::optional<uint32_t> watchdog;std::optional<float> internal;int motor_zero_frames=0;
  auto rx=peer->create_subscription<can_msgs::msg::Frame>("/from_can_bus",100,[&](can_msgs::msg::Frame::ConstSharedPtr f){
   if(!f->is_extended||f->dlc!=8||(f->id&255)!=253||((f->id>>8)&255)!=33||((f->id>>16)&255))return;
   int kind=(f->id>>24)&31,index=f->data[0]|(f->data[1]<<8);
   if(kind==17&&index==0x7028){uint32_t v;std::memcpy(&v,f->data.data()+4,4);watchdog=v;}
   if(kind==9&&index==0x3016&&f->data[2]==6){float v;std::memcpy(&v,f->data.data()+4,4);internal=v;}
  });
  auto sent=peer->create_subscription<can_msgs::msg::Frame>("/to_can_bus",100,[&](can_msgs::msg::Frame::ConstSharedPtr f){if(f->is_extended&&((f->id>>24)&31)==6&&(f->id&255)==33)++motor_zero_frames;});
  auto request=[&](int kind,int index){can_msgs::msg::Frame f;f.id=(kind<<24)|(253<<8)|33;f.is_extended=true;f.dlc=8;f.data[0]=index&255;f.data[1]=index>>8;tx->publish(f);};
  const auto until=std::chrono::steady_clock::now()+6s;
  while(std::chrono::steady_clock::now()<until&&(!watchdog||!internal)){request(17,0x7028);request(9,0x3016);executor.spin_all(2ms);std::this_thread::sleep_for(30ms);}
  if(!watchdog||*watchdog!=4000||!internal)throw std::runtime_error("Read-only preflight failed");
  rs::DriverConfiguration cfg;cfg.settings.transport.node_name="origin_live_driver";cfg.settings.feedback_timeout=500ms;cfg.settings.fail_on_feedback_timeout=false;cfg.settings.recovery_timeout=120s;
  rs::JointData j;j.name="el05_33";j.can_id=33;j.can_timeout_ticks=4000;j.limits=rs::motor_profile("EL05");j.kp=5;j.kd=1;j.command_limits={j.limits.position_min,j.limits.position_max,-1,1,-6,6};cfg.joints.push_back(j);
  rs::RobStrideDriver driver(rclcpp::get_logger("zero_live_check"));
  if(!driver.initialize(cfg)||!driver.open()||!driver.start()||!driver.apply_command_modes({{false,true,false}}))throw std::runtime_error("Startup failed");
  auto & joint=driver.joints()[0];
  while(*internal<7.8){if(!driver.update_state()||joint.state.fault)throw std::runtime_error("Position setup feedback failure");joint.command.velocity=.8;if(!driver.send_commands())throw std::runtime_error("Position setup write failure");request(9,0x3016);executor.spin_all(2ms);std::this_thread::sleep_for(20ms);}
  joint.command.velocity=0;for(int i=0;i<50;++i){driver.update_state();driver.send_commands();request(9,0x3016);executor.spin_all(2ms);std::this_thread::sleep_for(20ms);}
  for(int i=0;i<20&&!driver.validate_command_modes({{true,false,false}});++i){if(!driver.update_state()||!driver.send_commands())throw std::runtime_error("Pre-hold synchronization failed");executor.spin_all(2ms);std::this_thread::sleep_for(20ms);}
  std::string activation_error;
  if(!driver.apply_command_modes({{true,false,false}},&activation_error))throw std::runtime_error("Position mode activation failed: "+activation_error);
  auto target=joint.checked_position_command(joint.command.position);if(!target||std::abs(*target-*internal)>.03)throw std::runtime_error("Initial hold target mismatch");
  for(int i=0;i<5;++i){if(!driver.update_state()||!driver.send_commands()||joint.position_reference_changed)throw std::runtime_error("Initial hold was not established");std::this_thread::sleep_for(20ms);}
  std::cout<<"POWER_CYCLE_READY"<<std::endl;
  bool saw_power_cycle=false;
  double last=joint.state.position;auto end=std::chrono::steady_clock::now()+600s;
  while(std::chrono::steady_clock::now()<end){
   bool ok=driver.update_state();joint.command.velocity=0;bool sent=driver.send_commands();
   request(9,0x3016);executor.spin_all(2ms);
   std::cout<<std::setprecision(12)<<"{\"event\":\"power_monitor\",\"joint_position\":"<<joint.state.position<<",\"motor_internal_position\":"<<*internal<<",\"velocity\":"<<joint.state.velocity<<",\"fault\":"<<joint.state.fault<<",\"read_ok\":"<<ok<<",\"write_ok\":"<<sent<<"}"<<std::endl;
   if(!ok||!sent||joint.state.fault||std::abs(joint.state.velocity)>.5||std::abs(joint.state.position-last)>.03)throw std::runtime_error("Power-cycle monitoring guard failed");
   last=joint.state.position;std::this_thread::sleep_for(20ms);
   if(joint.position_reference_changed){
    saw_power_cycle=true;
    std::cout<<"POSITION_BLOCKED_AFTER_REBOOT"<<std::endl;
    for(int i=0;i<20;++i){if(!driver.update_state()||!driver.send_commands())throw std::runtime_error("Neutral recovery cycle failed");std::this_thread::sleep_for(20ms);}
    if(!driver.apply_command_modes({{false,false,false}})||!driver.apply_command_modes({{true,false,false}}))throw std::runtime_error("Explicit position reactivation failed");
    const double held=joint.state.position;
    auto target=joint.checked_position_command(joint.command.position);if(!target)throw std::runtime_error("Reactivated target unavailable");
    std::cout<<"REACTIVATED ros="<<held<<" motor_target="<<*target<<std::endl;
    for(int i=0;i<60;++i){if(!driver.update_state()||!driver.send_commands()||std::abs(joint.state.position-held)>.03||std::abs(joint.state.velocity)>.5)throw std::runtime_error("Reactivated hold moved unexpectedly");std::this_thread::sleep_for(20ms);}
    std::cout<<"REACTIVATED_HOLD_PASSED"<<std::endl;break;
   }
  }
  if(!saw_power_cycle)throw std::runtime_error("No power cycle observed: test incomplete");
  driver.stop();driver.close();executor.spin_all(5ms);
  if(motor_zero_frames)throw std::runtime_error("Unexpected Type 6 motor-zero frame");
  std::cout<<"{\"event\":\"complete\",\"stopped\":true,\"type6_frames\":"<<motor_zero_frames<<"}"<<std::endl;result=0;
 }catch(const std::exception &e){std::cerr<<e.what()<<std::endl;}
 rclcpp::shutdown();return result;
}
