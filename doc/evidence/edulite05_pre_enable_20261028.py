from pathlib import Path
exec(Path('/results/rotation_relation.py').read_text().split('old_watchdog=None')[0])
try:
 deadline=time.monotonic()+6
 while pub.get_subscription_count()==0 and time.monotonic()<deadline:rclpy.spin_once(n,timeout_sec=.05)
 time.sleep(2)
 state(4)
 for phase in ['stopped','neutral_before_enable','enabled']:
  if phase=='neutral_before_enable':motion(0,0)
  if phase=='enabled':state(3)
  for k in range(10):
   if phase=='enabled':motion(0,0)
   q=read(17,0x7019,'f');v=read(17,0x701B,'f');iq=read(17,0x701A,'f')
   emit(event='pre_enable_sample',phase=phase,position=q,velocity=v,iq=iq)
   if not math.isfinite(q) or abs(v)>.5 or abs(iq)>1:raise RuntimeError('Neutral-enable guard failed')
   time.sleep(.02)
finally:
 try:emit(event='stopped',mode=state(4))
 finally:n.destroy_node();rclpy.shutdown()
