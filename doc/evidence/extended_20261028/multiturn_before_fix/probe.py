import json,time,subprocess,signal,math,sys,struct
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
can_pub=n.create_publisher(Frame,'/to_can_bus',100)
voltage={};native={};voltage_next=0.;tripped=False
waiting=False;audit_hold=False;reset_seen=set();unexpected=[];raw_peak={33:0.,34:0.}
def can_rx(f):
 global tripped
 if f.is_extended and f.dlc==8 and ((f.id>>24)&31)==17 and bytes(f.data[:2])==bytes.fromhex('1c70'):
  mid=(f.id>>8)&255
  voltage[mid]=struct.unpack_from('<f',bytes(f.data),4)[0]
  emit(event='vbus',motor_id=mid,voltage=voltage[mid])
 if f.is_extended and f.dlc==8 and ((f.id>>24)&31)==17:
  mid=(f.id>>8)&255;idx=int.from_bytes(bytes(f.data[:2]),'little')
  if mid==34 and idx in [0x7019,0x701d]:
   value=struct.unpack_from('<f' if idx==0x7019 else '<h',bytes(f.data),4)[0]
   native[idx]=(time.time(),value)
 if not f.is_extended or f.dlc!=8 or ((f.id>>24)&31)!=2:return
 mid=(f.id>>8)&255
 if mid not in [33,34]:return
 v=-50+100*int.from_bytes(bytes(f.data[2:4]),'big')/65535
 if audit_hold:
  mode=(f.id>>22)&3
  if mode==2:raw_peak[mid]=max(raw_peak[mid],abs(v))
  elif abs(v)>.5:emit(event='nonrun_velocity_not_motion',motor_id=mid,mode=mode,raw_velocity=v,data=bytes(f.data).hex())
  if (mode==2 and abs(v)>.5) or ((f.id>>16)&63):
   unexpected.append((mid,v,f.id))
   if not tripped:
    tripped=True;emit(event='GUARD_TRIPPED',motor_id=mid,velocity=v,latest_voltage=voltage)
    for motor in [33,34]:
     stop=Frame();stop.id=(4<<24)|(253<<8)|motor;stop.is_extended=True;stop.dlc=8;can_pub.publish(stop)
 if waiting and ((f.id>>22)&3)==0:reset_seen.add(mid)
can_sub=n.create_subscription(Frame,'/from_can_bus',can_rx,1000)
sub=n.create_subscription(JointState,'/joint_states',rx,100)
description=n.create_publisher(String,'/robot_description',QoSProfile(depth=1,durability=DurabilityPolicy.TRANSIENT_LOCAL,reliability=ReliabilityPolicy.RELIABLE))
doc=String();doc.data=Path('/work/extended-final/multiturn/robot.urdf').read_text()
pubs={k:n.create_publisher(Float64MultiArray,'/'+k+'/commands',10) for k in ['pos','vel','hold']};desired={}
limit=n.create_publisher(Bool,'/test/virtual_limit_34',10)
log=open('/work/extended-final/multiturn/manager.log','w');cm=None

def spin(t=.02):
 global voltage_next
 if waiting and not reset_seen and not unexpected and time.monotonic()>=voltage_next:
  voltage_next=time.monotonic()+.02
  for mid in [33,34]:
   f=Frame();f.id=(17<<24)|(253<<8)|mid;f.is_extended=True;f.dlc=8;f.data[0]=0x1c;f.data[1]=0x70;can_pub.publish(f)
 for k,v in desired.items():m=Float64MultiArray();m.data=[v];pubs[k].publish(m)
 rclpy.spin_once(n,timeout_sec=t)
def snapshot(label):
 requested=time.time()
 for _ in range(3):
  for idx in [0x7019,0x701d]:
   f=Frame();f.id=(17<<24)|(253<<8)|34;f.is_extended=True;f.dlc=8;f.data[0]=idx&255;f.data[1]=idx>>8;can_pub.publish(f)
  end=time.monotonic()+.2
  while time.monotonic()<end:
   spin(.005)
   if all(k in native and native[k][0]>=requested for k in [0x7019,0x701d]):
    emit(event='multiturn_snapshot',label=label,state=state,internal_position=native[0x7019][1],rotation_counter=native[0x701d][1]);return
 raise RuntimeError('Multiturn metadata read failed')

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
 cm=subprocess.Popen(['ros2','run','controller_manager','ros2_control_node','--ros-args','--params-file','/work/extended-final/multiturn/controllers.yaml'],stdout=log,stderr=subprocess.STDOUT,start_new_session=True)
 for name in ['jsb','pos','vel','hold']:
  q=LoadController.Request();q.name=name
  if not call('/controller_manager/load_controller',LoadController,q,20).ok:raise RuntimeError('Load '+name)
  q=ConfigureController.Request();q.name=name
  if not call('/controller_manager/configure_controller',ConfigureController,q).ok:raise RuntimeError('Configure '+name)
 switch(['jsb']);wait_state();desired['hold']=state['q33'];switch(['hold']);run_for(.3)
 restarting=len(sys.argv)>1 and sys.argv[1]=='restart'
 if not restarting:
  initial=state['q'];peak_target=initial+3*math.tau;hold_target=initial+1.9*math.tau
  snapshot('before_rotation')
  desired['vel']=.7;switch(['vel']);deadline=time.monotonic()+40
  while state['q']<peak_target:
   spin(.01)
   if abs(state['v'])>1.2 or abs(state['v33'])>.5:raise RuntimeError('Preparation speed exceeded')
   if time.monotonic()>deadline:raise RuntimeError('Forward three turns timed out')
  desired['vel']=0.;run_for(1);stopped();switch([],['vel']);desired.pop('vel')
  snapshot('after_three_turns')
  switch(['pos'],expect=False)  # Internal position exceeds +/-4pi; must not modulo it.
  desired['vel']=-.7;switch(['vel']);deadline=time.monotonic()+25
  while state['q']>hold_target:
   spin(.01)
   if abs(state['v'])>1.2 or abs(state['v33'])>.5:raise RuntimeError('Reverse preparation speed exceeded')
   if time.monotonic()>deadline:raise RuntimeError('Return to representable hold timed out')
  desired['vel']=0.;run_for(1);stopped();switch([],['vel']);desired.pop('vel')
  snapshot('multiturn_hold_before_power')
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
  snapshot('after_power_reactivation')
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
