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
  rs::DriverConfiguration cfg;cfg.settings.transport.node_name="origin_live_driver";cfg.settings.feedback_timeout=500ms;
  rs::JointData j;j.name="el05_33";j.can_id=33;j.can_timeout_ticks=4000;j.limits=rs::motor_profile("EL05");j.kp=5;j.kd=1;j.command_limits={j.limits.position_min,j.limits.position_max,-1,1,-6,6};cfg.joints.push_back(j);
  rs::RobStrideDriver driver(rclcpp::get_logger("zero_live_check"));
  if(!driver.initialize(cfg)||!driver.open()||!driver.start()||!driver.apply_command_modes({{false,true,false}}))throw std::runtime_error("Startup failed");
  auto & joint=driver.joints()[0];
  auto tick=[&](double speed){if(!driver.update_state()||joint.state.fault)throw std::runtime_error("Feedback failure");joint.command.velocity=speed;if(!driver.send_commands())throw std::runtime_error("Write failure");request(9,0x3016);executor.spin_all(2ms);std::this_thread::sleep_for(20ms);};
  auto call=[&](const std::string & name){auto client=peer->create_client<std_srvs::srv::Trigger>("/origin_live_driver/"+name+"_33");if(!client->wait_for_service(3s))throw std::runtime_error("Service unavailable");auto f=client->async_send_request(std::make_shared<std_srvs::srv::Trigger::Request>());auto end=std::chrono::steady_clock::now()+3s;while(f.wait_for(0ms)!=std::future_status::ready){executor.spin_all(2ms);if(std::chrono::steady_clock::now()>end)throw std::runtime_error("Service timeout");std::this_thread::sleep_for(5ms);}auto r=f.get();std::cout<<"service "<<name<<" success="<<r->success<<" message="<<r->message<<std::endl;return r->success;};
  const bool hold_only=argc>1&&(std::string(argv[1])=="hold"||std::string(argv[1])=="mismatch");
  if(!hold_only){
   if(!driver.apply_command_modes({{false,false,false}})||!call("begin_homing"))throw std::runtime_error("Begin homing failed");
   if(!driver.apply_command_modes({{false,true,false}}))throw std::runtime_error("Homing velocity activation failed");
   for(int i=0;i<50;++i)tick(.2);
   for(int i=0;i<200;++i){tick(0);if(i>20&&std::abs(joint.state.velocity)<.02)break;}
   std::cout<<"before_finish velocity="<<joint.state.velocity<<" position="<<joint.state.position<<std::endl;
   if(!driver.apply_command_modes({{false,false,false}})||!call("finish_homing"))throw std::runtime_error("Finish homing failed");
   if(!driver.update_state()||!call("homing_ready"))throw std::runtime_error("Homing confirmation failed");
  }
  for(int i=0;i<5;++i)tick(0);  // Run normal read cycles before requesting position.
  if(!driver.apply_command_modes({{true,false,false}}))throw std::runtime_error("Position activation rejected");
  const double initial=joint.state.position;double maximum=0,peak_speed=0;
  if(argc>1&&std::string(argv[1])=="mismatch"){
    joint.command.position=initial+.5;
    for(int i=0;i<20;++i){tick(0);if(std::abs(joint.state.position-initial)>.03||std::abs(joint.state.velocity)>.5)throw std::runtime_error("Mismatched startup moved unexpectedly");}
    if(!joint.position_reference_changed)throw std::runtime_error("Mismatched startup was not inhibited");
    std::cout<<"STARTUP_MISMATCH_INHIBITED"<<std::endl;
    if(!driver.apply_command_modes({{false,false,false}})||!driver.apply_command_modes({{true,false,false}}))throw std::runtime_error("Mismatch recovery failed");
  }
  auto target=joint.checked_position_command(joint.command.position);if(!target)throw std::runtime_error("Target unavailable");
  std::cout<<"pre_hold ros="<<initial<<" target="<<*target<<std::endl;
  for(int i=0;i<60;++i){tick(0);maximum=std::max(maximum,std::abs(joint.state.position-initial));peak_speed=std::max(peak_speed,std::abs(joint.state.velocity));if(maximum>.03||peak_speed>.5)throw std::runtime_error("Unexpected position-hold motion");}
  std::cout<<"hold maximum_motion="<<maximum<<" peak_speed="<<peak_speed<<std::endl;
  driver.stop();driver.close();executor.spin_all(5ms);
  if(motor_zero_frames!=(hold_only?0:1))throw std::runtime_error("Unexpected motor-zero count");
  std::cout<<"{\"event\":\"complete\",\"stopped\":true,\"type6_frames\":"<<motor_zero_frames<<"}"<<std::endl;result=0;
 }catch(const std::exception &e){std::cerr<<e.what()<<std::endl;}
 rclcpp::shutdown();return result;
}
