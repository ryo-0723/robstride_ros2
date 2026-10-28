import json,time,subprocess,signal,math
from pathlib import Path
import rclpy
from rclpy.qos import QoSProfile,DurabilityPolicy,ReliabilityPolicy
from std_msgs.msg import String,Float64MultiArray
from sensor_msgs.msg import JointState
from std_srvs.srv import Trigger
from controller_manager_msgs.srv import LoadController,ConfigureController,SwitchController
rclpy.init();n=rclpy.create_node('final_cm_probe');start=time.monotonic();state=None

def emit(**x):print(json.dumps(dict(unix_s=time.time(),**x)),flush=True)
def rx(m):
 global state
 if 'robstride_joint' in m.name:
  i=m.name.index('robstride_joint');state={'q':m.position[i],'v':m.velocity[i],'t':time.monotonic()}
sub=n.create_subscription(JointState,'/joint_states',rx,100)
description=n.create_publisher(String,'/robot_description',QoSProfile(depth=1,durability=DurabilityPolicy.TRANSIENT_LOCAL,reliability=ReliabilityPolicy.RELIABLE))
doc=String();doc.data=Path('/work/final-cm/robot.urdf').read_text()
pubs={k:n.create_publisher(Float64MultiArray,'/'+k+'/commands',10) for k in ['pos','vel']};desired={}
log=open('/work/final-cm/manager.log','w');cm=None

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
def service(name):
 r=call('/final_system_can_transport/'+name+'_33',Trigger,Trigger.Request());emit(event='service',name=name,success=r.success,message=r.message);return r.success

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
   if abs(state['v'])>1 or (origin is not None and abs(state['q']-origin)>allowance):raise RuntimeError('Unexpected CM motion')
 emit(event='observed',state=state,peak_velocity=peak)

def stopped():
 end=time.monotonic()+6
 while True:
  spin()
  if state and abs(state['v'])<.02 and time.monotonic()-state['t']<.3:return
  if time.monotonic()>end:raise RuntimeError('Motor did not settle')

try:
 description.publish(doc)
 cm=subprocess.Popen(['ros2','run','controller_manager','ros2_control_node','--ros-args','--params-file','/work/final-cm/controllers.yaml'],stdout=log,stderr=subprocess.STDOUT,start_new_session=True)
 for name in ['jsb','pos','vel']:
  q=LoadController.Request();q.name=name
  if not call('/controller_manager/load_controller',LoadController,q,20).ok:raise RuntimeError('Load '+name)
  q=ConfigureController.Request();q.name=name
  if not call('/controller_manager/configure_controller',ConfigureController,q).ok:raise RuntimeError('Configure '+name)
 switch(['jsb']);wait_state();origin=state['q'];desired['pos']=origin
 switch(['pos']);run_for(.5,origin,.03)
 desired['pos']=origin+.02;run_for(1,origin,.06)
 desired['pos']=origin;run_for(1,origin,.06)
 switch([],['pos']);desired.clear();stopped()
 if not service('begin_homing'):raise RuntimeError('Begin homing')
 switch(['pos'],expect=False)
 desired['vel']=.2;switch(['vel']);run_for(1)
 desired['vel']=0.;run_for(1);stopped();switch([],['vel']);desired.clear()
 if not service('finish_homing'):raise RuntimeError('Finish homing')
 end=time.monotonic()+8
 while not service('homing_ready'):
  spin(.1);time.sleep(.1)
  if time.monotonic()>end:raise RuntimeError('Homing readiness timeout')
 run_for(.3);wait_state()
 if abs(state['q'])>.01:raise RuntimeError('New origin is not zero')
 desired['pos']=state['q'];switch(['pos']);run_for(1,state['q'],.03)
 switch([],['pos']);desired.clear()
 emit(event='cm_integration_passed')
finally:
 if cm is not None:
  try:cm.send_signal(signal.SIGINT);cm.wait(timeout=8)
  except subprocess.TimeoutExpired:cm.kill();cm.wait()
 log.close();n.destroy_node();rclpy.shutdown()
