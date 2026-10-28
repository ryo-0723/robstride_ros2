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
   if(!f->is_extended||f->dlc!=8||(f->id&255)!=253||((f->id>>8)&255)!=34||((f->id>>16)&255))return;
   int kind=(f->id>>24)&31,index=f->data[0]|(f->data[1]<<8);
   if(kind==17&&index==0x7028){uint32_t v;std::memcpy(&v,f->data.data()+4,4);watchdog=v;}
   if(kind==17&&index==0x701a){float v;std::memcpy(&v,f->data.data()+4,4);iq=v;}
   if(kind==9&&index==0x3016&&f->data[2]==6){float v;std::memcpy(&v,f->data.data()+4,4);internal=v;}
  });
  auto sent=peer->create_subscription<can_msgs::msg::Frame>("/to_can_bus",100,[&](can_msgs::msg::Frame::ConstSharedPtr f){if(f->is_extended&&((f->id>>24)&31)==6&&(f->id&255)==34)++motor_zero_frames;});
  auto request=[&](int kind,int index){can_msgs::msg::Frame f;f.id=(kind<<24)|(253<<8)|34;f.is_extended=true;f.dlc=8;f.data[0]=index&255;f.data[1]=index>>8;tx->publish(f);};
  const auto until=std::chrono::steady_clock::now()+6s;
  while(std::chrono::steady_clock::now()<until&&(!watchdog||!internal)){request(17,0x7028);request(9,0x3016);executor.spin_all(2ms);std::this_thread::sleep_for(30ms);}
  if(!watchdog||*watchdog!=4000||!internal)throw std::runtime_error("Read-only preflight failed");
  rs::DriverConfiguration cfg;cfg.settings.transport.node_name="origin_live_driver";cfg.settings.feedback_timeout=500ms;
  rs::JointData j;j.name="el05_34";j.can_id=34;j.can_timeout_ticks=4000;j.limits=rs::motor_profile("EL05");j.kp=5;j.kd=.05;j.command_limits={j.limits.position_min,j.limits.position_max,-50,50,-6,6};cfg.joints.push_back(j);
  rs::RobStrideDriver driver(rclcpp::get_logger("zero_live_check"));
  if(!driver.initialize(cfg)||!driver.open()||!driver.start()||!driver.apply_command_modes({{false,true,false}}))throw std::runtime_error("Startup failed");
  auto & joint=driver.joints()[0];
  auto tick=[&](double speed){if(!driver.update_state()||joint.state.fault!=0)throw std::runtime_error("Feedback health failed");
    if(std::abs(joint.state.velocity)>50.2||joint.state.temperature>65||(iq&&std::abs(*iq)>10))throw std::runtime_error("Operating envelope exceeded");
    joint.command.velocity=speed;if(!driver.send_commands())throw std::runtime_error("Command rejected");request(17,0x701a);executor.spin_all(2ms);std::this_thread::sleep_for(10ms);};
  for(double speed: {0.,.3,1.,5.,10.,20.,30.,40.,50.,40.,30.,20.,10.,5.,1.,0.,-.3,-1.,-5.,-10.,-20.,-30.,-40.,-50.,-40.,-30.,-20.,-10.,-5.,-1.,0.}){
   double vmax=0,imax=0;for(int i=0;i<80;++i){tick(speed);vmax=std::max(vmax,std::abs(joint.state.velocity));if(iq)imax=std::max(imax,double(std::abs(*iq)));}
   std::cout<<std::setprecision(12)<<"{\"event\":\"velocity_plateau\",\"command\":"<<speed<<",\"measured_velocity\":"<<joint.state.velocity<<",\"peak_abs_velocity\":"<<vmax<<",\"peak_abs_iq\":"<<imax<<",\"position\":"<<joint.state.position<<"}"<<std::endl;
  }
  driver.stop();driver.close();executor.spin_all(5ms);
  if(motor_zero_frames)throw std::runtime_error("Unexpected Type 6 motor-zero frame");
  std::cout<<"{\"event\":\"complete\",\"stopped\":true,\"type6_frames\":"<<motor_zero_frames<<"}"<<std::endl;result=0;
 }catch(const std::exception &e){std::cerr<<e.what()<<std::endl;}
 rclcpp::shutdown();return result;
}
