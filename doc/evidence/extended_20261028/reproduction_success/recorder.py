import json,time,signal,struct
import rclpy
from can_msgs.msg import Frame
rclpy.init();n=rclpy.create_node('final_encoder_wire_audit');running=True

def log(direction,f):
 if not f.is_extended or f.dlc!=8:return
 kind=(f.id>>24)&31
 mid=(f.id&255) if direction=='tx' else ((f.id>>8)&255)
 if mid not in (33,34):return
 d=bytes(f.data);x={'motor_id':mid,'unix_s':time.time(),'monotonic_s':time.monotonic(),'direction':direction,'type':kind,'id':hex(f.id),'data':d.hex()}
 if direction=='rx' and kind==2:
  x.update(mode=(f.id>>22)&3,fault=(f.id>>16)&63,position=-12.566370614+25.132741228*int.from_bytes(d[:2],'big')/65535,velocity=-50+100*int.from_bytes(d[2:4],'big')/65535)
 if direction=='rx' and kind==17 and d[:2]==bytes.fromhex('1c70'):
  x.update(vbus=struct.unpack_from('<f',d,4)[0])
 if direction=='tx' and kind==1:
  x.update(position=-12.566370614+25.132741228*int.from_bytes(d[:2],'big')/65535,kp=500*int.from_bytes(d[4:6],'big')/65535,kd=5*int.from_bytes(d[6:8],'big')/65535)
 print(json.dumps(x),flush=True)
subs=[n.create_subscription(Frame,t,lambda f,d=d:log(d,f),1000) for t,d in [('/to_can_bus','tx'),('/from_can_bus','rx')]]
def stop(*args):
 global running
 running=False
signal.signal(signal.SIGTERM,stop)
while running and rclpy.ok():rclpy.spin_once(n,timeout_sec=.05)
n.destroy_node();rclpy.shutdown()
