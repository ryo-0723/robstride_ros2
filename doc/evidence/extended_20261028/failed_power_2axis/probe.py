import json,time,subprocess,signal,math,sys
from pathlib import Path
import rclpy
from rclpy.qos import QoSProfile,DurabilityPolicy,ReliabilityPolicy
from std_msgs.msg import String,Float64MultiArray,Bool
from sensor_msgs.msg import JointState
from can_msgs.msg import Frame
from std_srvs.srv import Trigger
from controller_manager_msgs.srv import LoadController,ConfigureController,SwitchController
rclpy.init();n=rclpy.create_node('final_cm_probe');start=time.monotonic();state=None;last_rx=None;gaps=[]

def emit(**x):print(json.dumps(dict(unix_s=time.time(),**x)),flush=True)
def rx(m):
 global state,last_rx
 if 'robstride_joint' in m.name:
  i=m.name.index('robstride_joint');j=m.name.index('joint33');now=time.monotonic();
  if last_rx is not None:gaps.append(now-last_rx)
  last_rx=now
  state={'q':m.position[i],'v':m.velocity[i],'t':time.monotonic(),'q33':m.position[j],'v33':m.velocity[j],'stamp':m.header.stamp.sec+m.header.stamp.nanosec/1e9}
waiting=False;audit_hold=False;reset_seen=set();unexpected=[];raw_peak={33:0.,34:0.}
def can_rx(f):
 if not f.is_extended or f.dlc!=8 or ((f.id>>24)&31)!=2:return
 mid=(f.id>>8)&255
 if mid not in [33,34]:return
 v=-50+100*int.from_bytes(bytes(f.data[2:4]),'big')/65535
 if audit_hold:
  raw_peak[mid]=max(raw_peak[mid],abs(v))
  if abs(v)>.5 or ((f.id>>16)&63):unexpected.append((mid,v,f.id))
 if waiting and ((f.id>>22)&3)==0:reset_seen.add(mid)
can_sub=n.create_subscription(Frame,'/from_can_bus',can_rx,1000)
sub=n.create_subscription(JointState,'/joint_states',rx,100)
description=n.create_publisher(String,'/robot_description',QoSProfile(depth=1,durability=DurabilityPolicy.TRANSIENT_LOCAL,reliability=ReliabilityPolicy.RELIABLE))
doc=String();doc.data=Path('/work/extended-final/power-cm/robot.urdf').read_text()
pubs={k:n.create_publisher(Float64MultiArray,'/'+k+'/commands',10) for k in ['pos','vel','hold']};desired={}
limit=n.create_publisher(Bool,'/test/virtual_limit_34',10)
log=open('/work/extended-final/power-cm/manager.log','w');cm=None

def spin(t=.02):
 for k,v in desired.items():m=Float64MultiArray();m.data=[v];pubs[k].publish(m)
 rclpy.spin_once(n,timeout_sec=t)
def call(srv,typ,req,timeout=12):
 c=n.create_client(typ,srv);end=time.monotonic()+timeout
 while not c.wait_for_service(timeout_sec=.1):
  spin()
  if time.monotonic()>end:raise RuntimeError('Service unavailable '+srv)
 f=c.call_async(req)
 while not f.done():
  spin()
  if time.monotonic()>end:raise RuntimeError('Service timeout '+srv)
 r=f.result();n.destroy_client(c);return r

def switch(on=[],off=[],expect=True):
 q=SwitchController.Request();q.activate_controllers=on;q.deactivate_controllers=off;q.strictness=2;q.timeout.sec=4
 r=call('/controller_manager/switch_controller',SwitchController,q)
 emit(event='switch',on=on,off=off,ok=r.ok)
 if r.ok!=expect:raise RuntimeError('Unexpected switch result')
def service(name,mid=34):
 r=call('/final_system_can_transport/'+name+'_'+str(mid),Trigger,Trigger.Request());emit(event='service',name=name,success=r.success,message=r.message);return r.success

def wait_state():
 end=time.monotonic()+8
 while state is None or not math.isfinite(state['q']) or not math.isfinite(state['v']) or time.monotonic()-state['t']>.5:
  spin()
  if time.monotonic()>end:raise RuntimeError('Joint state unavailable')

def run_for(seconds,origin=None,allowance=.15):
 end=time.monotonic()+seconds;peak=0
 while time.monotonic()<end:
  spin()
  if state:
   peak=max(peak,abs(state['v']))
   if abs(state['v'])>1 or abs(state['v33'])>.5 or (origin is not None and abs(state['q']-origin)>allowance):raise RuntimeError('Unexpected CM motion')
 emit(event='observed',state=state,peak_velocity=peak)

def stopped():
 end=time.monotonic()+6
 while True:
  spin()
  if state and abs(state['v'])<.02 and time.monotonic()-state['t']<.3:return
  if time.monotonic()>end:raise RuntimeError('Motor did not settle')

try:
 description.publish(doc)
 cm=subprocess.Popen(['ros2','run','controller_manager','ros2_control_node','--ros-args','--params-file','/work/extended-final/power-cm/controllers.yaml'],stdout=log,stderr=subprocess.STDOUT,start_new_session=True)
 for name in ['jsb','pos','vel','hold']:
  q=LoadController.Request();q.name=name
  if not call('/controller_manager/load_controller',LoadController,q,20).ok:raise RuntimeError('Load '+name)
  q=ConfigureController.Request();q.name=name
  if not call('/controller_manager/configure_controller',ConfigureController,q).ok:raise RuntimeError('Configure '+name)
 switch(['jsb']);wait_state();desired['hold']=state['q33'];switch(['hold']);run_for(.3)
 restarting=len(sys.argv)>1 and sys.argv[1]=='restart'
 if not restarting:
  desired['vel']=.5;switch(['vel']);deadline=time.monotonic()+25
  while state['q']<6.5:
   spin(.01)
   if abs(state['v'])>1.2 or abs(state['v33'])>.5:raise RuntimeError('Preparation speed exceeded')
   if time.monotonic()>deadline:raise RuntimeError('Preparation rotation timed out')
  desired['vel']=0.;run_for(1);stopped();switch([],['vel']);desired.pop('vel')
 origin=state['q'];origin33=state['q33'];desired['pos']=origin;switch(['pos']);run_for(.7,origin,.03)
 audit_hold=True
 if not restarting:
  waiting=True;emit(event='POWER_CYCLE_READY',state=state);deadline=time.monotonic()+600
  while reset_seen!={33,34}:
   spin(.02)
   if unexpected:raise RuntimeError('Independent speed/fault guard: '+str(unexpected))
   if abs(state['q']-origin)>.03 or abs(state['q33']-origin33)>.03:raise RuntimeError('Unexpected restored angle')
   if time.monotonic()>deadline:raise RuntimeError('No two-axis power cycle observed')
  waiting=False
  emit(event='both_reset_detected',ids=sorted(reset_seen),state=state)
  if service('homing_ready') or service('homing_ready',33):raise RuntimeError('Position unexpectedly auto-resumed')
  switch([],['pos','hold']);desired.clear();run_for(.2)
  deadline=time.monotonic()+8
  while not (service('homing_ready') and service('homing_ready',33)):
   spin(.05);time.sleep(.1)
   if time.monotonic()>deadline:raise RuntimeError('References not ready after release')
  desired['pos']=state['q'];desired['hold']=state['q33'];switch(['pos','hold'])
  run_for(1.2,origin,.03)
  if abs(state['q33']-origin33)>.03 or unexpected:raise RuntimeError('Two-axis reactivation moved unexpectedly')
  emit(event='two_axis_power_reactivation_passed',state=state,raw_peak_velocity=raw_peak,max_state_gap_s=max(gaps))
 else:
  run_for(1.2,origin,.03)
  if abs(state['q33']-origin33)>.03 or unexpected:raise RuntimeError('Two-axis restart moved unexpectedly')
  emit(event='two_axis_process_restart_passed',state=state,raw_peak_velocity=raw_peak,max_state_gap_s=max(gaps))
 switch([],['pos','hold']);desired.clear()

finally:
 if cm is not None:
  try:cm.send_signal(signal.SIGINT);cm.wait(timeout=8)
  except subprocess.TimeoutExpired:cm.kill();cm.wait()
 log.close();n.destroy_node();rclpy.shutdown()
