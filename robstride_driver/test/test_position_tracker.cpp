#include <cmath>
#include <limits>

#include <gtest/gtest.h>

#include "robstride_driver/position_tracker.hpp"

namespace rs = robstride_driver;
constexpr double kPi = 3.14159265358979323846;
constexpr double kWirePeriod = 8.0 * kPi;

TEST(PositionTracker, AccumulatesRepeatedForwardAndReverseCrossings)
{
  rs::PositionTracker tracker;
  for (int step = 0; step <= 1200; ++step) {
    const double expected = 0.1 * step;
    ASSERT_TRUE(tracker.update(std::remainder(expected, kWirePeriod), kWirePeriod));
    EXPECT_NEAR(tracker.position(), expected, 1e-11);
  }
  for (int step = 1200; step >= -1200; --step) {
    const double expected = 0.1 * step;
    ASSERT_TRUE(tracker.update(std::remainder(expected, kWirePeriod), kWirePeriod));
    EXPECT_NEAR(tracker.position(), expected, 1e-11);
  }
}

TEST(PositionTracker, StartsAtMeasuredCoordinateAndPreservesItOnRepeatedFrames)
{
  rs::PositionTracker tracker;
  ASSERT_TRUE(tracker.update(-2.5, kWirePeriod));
  ASSERT_TRUE(tracker.update(-2.5, kWirePeriod));
  EXPECT_DOUBLE_EQ(tracker.position(), -2.5);
}

TEST(PositionTracker, RestoresNearestRevolutionOrResetsToNewMeasurement)
{
  for (const auto policy : {rs::PositionRestartPolicy::restore, rs::PositionRestartPolicy::reset}) {
    rs::PositionTracker tracker;
    ASSERT_TRUE(tracker.update(2.44, kWirePeriod));
    for (int step = 1; step <= 190; ++step) {
      ASSERT_TRUE(tracker.update(std::remainder(2.44 + step * 0.1, kWirePeriod), kWirePeriod));
    }
    ASSERT_TRUE(tracker.restart(2.44 + 0.01, 2.0 * kPi, policy));
    const double expected = policy == rs::PositionRestartPolicy::restore ?
      2.45 + 6.0 * kPi : 2.45;
    EXPECT_NEAR(tracker.position(), expected, 1e-11);
    ASSERT_TRUE(tracker.update(2.55, kWirePeriod));
    EXPECT_NEAR(tracker.position(), expected + 0.1, 1e-11);
  }
}

TEST(PositionTracker, RejectsInvalidAndExactlyAmbiguousSamplesWithoutLosingHistory)
{
  rs::PositionTracker tracker;
  ASSERT_TRUE(tracker.update(1.0, kWirePeriod));
  EXPECT_FALSE(tracker.update(std::numeric_limits<double>::quiet_NaN(), kWirePeriod));
  EXPECT_FALSE(tracker.update(1.0, 0.0));
  EXPECT_FALSE(tracker.update(1.0, -1.0));
  EXPECT_FALSE(tracker.update(1.0, std::numeric_limits<double>::infinity()));
  EXPECT_FALSE(tracker.update(1.0 + kWirePeriod / 2.0, kWirePeriod));
  EXPECT_DOUBLE_EQ(tracker.position(), 1.0);
  ASSERT_TRUE(tracker.update(1.1, kWirePeriod));
  EXPECT_NEAR(tracker.position(), 1.1, 1e-12);
  tracker.clear();
  EXPECT_FALSE(tracker.initialized());
  ASSERT_TRUE(tracker.update(-1.0, kWirePeriod));
  EXPECT_DOUBLE_EQ(tracker.position(), -1.0);
}
