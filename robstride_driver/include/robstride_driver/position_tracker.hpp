#pragma once

#include <cmath>

namespace robstride_driver
{

enum class PositionRestartPolicy {reset, restore};

// Accumulate the shortest displacement between periodic observations. The first
// observation retains the motor's coordinate; it does not establish a new zero.
// Correctness requires less than half a period of motion between observations.
class PositionTracker
{
public:
  bool initialized() const noexcept {return initialized_;}
  double position() const noexcept {return position_;}
  double raw_position() const noexcept {return last_raw_;}
  double coordinate_shift() const noexcept {return initialized_ ? position_ - last_raw_ : 0.0;}

  void clear() noexcept {initialized_ = false;}

  bool update(double raw, double period) noexcept
  {
    if (!valid(raw, period)) {return false;}
    if (!initialized_) {return restart(raw, period, PositionRestartPolicy::reset);}
    const double delta = std::remainder(raw - last_raw_, period);
    return accept(raw, position_ + delta, delta, period);
  }

  // Restore chooses the coordinate equivalent nearest the last known position.
  // It cannot recover unobserved turns. A reboot can use a different period from
  // normal feedback wrapping (e.g. one output revolution versus an 8*pi wire range).
  bool restart(double raw, double period, PositionRestartPolicy policy) noexcept
  {
    if (!valid(raw, period)) {return false;}
    if (!initialized_ || policy == PositionRestartPolicy::reset) {
      last_raw_ = raw;
      position_ = raw;
      initialized_ = true;
      return true;
    }
    const double delta = std::remainder(raw - position_, period);
    return accept(raw, position_ + delta, delta, period);
  }

private:
  static bool valid(double raw, double period) noexcept
  {
    return std::isfinite(raw) && std::isfinite(period) && period > 0.0;
  }

  bool accept(double raw, double next, double delta, double period) noexcept
  {
    if (!std::isfinite(next) || !std::isfinite(delta) || std::abs(delta) >= period / 2.0) {
      return false;
    }
    last_raw_ = raw;
    position_ = next;
    return true;
  }

  bool initialized_{false};
  double last_raw_{0.0};
  double position_{0.0};
};

}  // namespace robstride_driver
