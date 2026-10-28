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
  std::optional<uint32_t> watchdog;std::optional<float> internal;std::optional<float> iq;int motor_zero_frames=0;
  auto rx=peer->create_subscription<can_msgs::msg::Frame>("/from_can_bus",100,[&](can_msgs::msg::Frame::ConstSharedPtr f){
   if(!f->is_extended||f->dlc!=8||(f->id&255)!=253||((f->id>>8)&255)!=33||((f->id>>16)&255))return;
   int kind=(f->id>>24)&31,index=f->data[0]|(f->data[1]<<8);
   if(kind==17&&index==0x7028){uint32_t v;std::memcpy(&v,f->data.data()+4,4);watchdog=v;}
   if(kind==17&&index==0x701a){float v;std::memcpy(&v,f->data.data()+4,4);iq=v;}
   if(kind==9&&index==0x3016&&f->data[2]==6){float v;std::memcpy(&v,f->data.data()+4,4);internal=v;}
  });
  auto sent=peer->create_subscription<can_msgs::msg::Frame>("/to_can_bus",100,[&](can_msgs::msg::Frame::ConstSharedPtr f){if(f->is_extended&&((f->id>>24)&31)==6&&(f->id&255)==33)++motor_zero_frames;});
  auto request=[&](int kind,int index){can_msgs::msg::Frame f;f.id=(kind<<24)|(253<<8)|33;f.is_extended=true;f.dlc=8;f.data[0]=index&255;f.data[1]=index>>8;tx->publish(f);};
  const auto until=std::chrono::steady_clock::now()+6s;
  while(std::chrono::steady_clock::now()<until&&(!watchdog||!internal)){request(17,0x7028);request(9,0x3016);executor.spin_all(2ms);std::this_thread::sleep_for(30ms);}
  if(!watchdog||*watchdog!=4000||!internal)throw std::runtime_error("Read-only preflight failed");
  rs::DriverConfiguration cfg;cfg.settings.transport.node_name="origin_live_driver";cfg.settings.feedback_timeout=500ms;
  rs::JointData j;j.name="el05_33";j.can_id=33;j.can_timeout_ticks=4000;j.limits=rs::motor_profile("EL05");j.kp=5;j.kd=1;j.command_limits={j.limits.position_min,j.limits.position_max,-10,10,-5.4,5.4};cfg.joints.push_back(j);
  rs::RobStrideDriver driver(rclcpp::get_logger("zero_live_check"));
  if(!driver.initialize(cfg)||!driver.open()||!driver.start()||!driver.apply_command_modes({{false,true,true}}))throw std::runtime_error("Startup failed");
  auto & joint=driver.joints()[0];
  auto tick=[&](double effort){
   if(!driver.update_state()||joint.state.fault||!std::isfinite(joint.state.velocity)||std::abs(joint.state.velocity)>10||joint.state.temperature>65||(iq&&std::abs(*iq)>9.8))throw std::runtime_error("Effort envelope guard failed");
   joint.command.velocity=0;joint.command.effort=effort;
   if(!driver.send_commands())throw std::runtime_error("Effort command rejected");
   request(17,0x701a);executor.spin_all(2ms);std::this_thread::sleep_for(2ms);
  };
  for(double effort:{.1,.5,1.,2.,3.,4.,5.,5.4,-.1,-.5,-1.,-2.,-3.,-4.,-5.,-5.4}){
   double peak_iq=0,peak_speed=0;const auto end=std::chrono::steady_clock::now()+80ms;
   while(std::chrono::steady_clock::now()<end){tick(effort);if(iq)peak_iq=std::max(peak_iq,double(std::abs(*iq)));peak_speed=std::max(peak_speed,std::abs(joint.state.velocity));}
   const auto rest=std::chrono::steady_clock::now()+350ms;
   while(std::chrono::steady_clock::now()<rest){tick(0);if(iq)peak_iq=std::max(peak_iq,double(std::abs(*iq)));peak_speed=std::max(peak_speed,std::abs(joint.state.velocity));}
   std::cout<<std::setprecision(12)<<"{\"event\":\"effort_pulse\",\"motor_id\":33,\"effort_command\":"<<effort<<",\"wire_kd\":1,\"peak_sampled_iq\":"<<peak_iq<<",\"peak_sampled_velocity\":"<<peak_speed<<",\"position\":"<<joint.state.position<<"}"<<std::endl;
  }
  driver.stop();driver.close();executor.spin_all(5ms);
  if(motor_zero_frames)throw std::runtime_error("Unexpected Type 6 motor-zero frame");
  std::cout<<"{\"event\":\"complete\",\"stopped\":true,\"type6_frames\":"<<motor_zero_frames<<"}"<<std::endl;result=0;
 }catch(const std::exception &e){std::cerr<<e.what()<<std::endl;}
 rclcpp::shutdown();return result;
}
