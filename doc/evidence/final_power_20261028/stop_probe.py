from pathlib import Path
exec(Path('/results/rotation_relation.py').read_text().split('old_watchdog=None')[0])
try:
 deadline=time.monotonic()+5
 while pub.get_subscription_count()==0 and time.monotonic()<deadline:rclpy.spin_once(n,timeout_sec=.05)
 deadline=time.monotonic()+8
 while sub.get_publisher_count()==0 and time.monotonic()<deadline:rclpy.spin_once(n,timeout_sec=.05)
 for _ in range(20):rclpy.spin_once(n,timeout_sec=.05)
 f=None
 for _ in range(3):
  try:f=exchange(4,bytes(8),lambda f:((f.id>>24)&31)==2);break
  except RuntimeError:
   for _ in range(10):rclpy.spin_once(n,timeout_sec=.05)
 if f is None:raise RuntimeError('Stop response unavailable after 3 attempts')
 b=bytes(f.data)
 position=-12.566370614+25.132741228*int.from_bytes(b[:2],'big')/65535
 emit(event='stop_feedback',mode=(f.id>>22)&3,faults=(f.id>>16)&63,wire_position=position)
 for index,name,fmt in [(0x3014,'rotation','i'),(0x3016,'mechPos','f'),(0x3045,'theta_mech_1','f'),(0x3012,'cmdPos','f'),(0x3044,'low_position','f')]:
  value=read(9,index,fmt);emit(event='parameter',index=hex(index),name=name,value=value)
finally:n.destroy_node();rclpy.shutdown()
