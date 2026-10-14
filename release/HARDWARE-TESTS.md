# Hardware acceptance tests

Release: 1.0.1. Tester: __________________. Watch model / firmware: __________________.

Run these tests on a compatible physical watch before public submission. Repeat layout and button checks on the 255S if possible; simulator results alone do not validate real GPS, vibration, sound, or FIT synchronization.

| Test | Expected result | Result / notes |
| --- | --- | --- |
| Cold launch without GPS | App remains usable; starting an interval shows a GPS message and does not create a running timer | Pending |
| Pace selection | Exactly 12 paces; bounds 5:30 and 2:45; UP selects a faster pace; DOWN selects a slower pace | Pending |
| Start with usable GPS | Timer starts and a FIT running activity begins | Pending |
| Run at or faster than target | Below-target countdown remains/reset to zero | Pending |
| Run slower for less than 60 seconds, then recover | Countdown resets; interval keeps running | Pending |
| Run slower continuously for 60 seconds | Interval stops once; vibration/sound occur where supported; rest starts | Pending |
| Stand still with usable GPS | Zero speed counts as below target, including the 60-second stopping rule | Pending |
| Lose GPS during an interval | No false slow-stop; countdown resets; the interval cannot set a best record | Pending |
| Manual stop | START or BACK ends the interval; rest begins; history updates once | Pending |
| Three-minute rest | No alert before 3:00; one alert on the first check after 3:00; no repeated alert | Pending |
| Five-minute rest | Activity/history save and application exits at the first check at/after 5:00 | Pending |
| Restart just before rest deadline | Rest duration is recorded; next interval begins; old rest deadline does not terminate it | Pending |
| Change pace between intervals | Next interval uses the new pace; previous record keeps the original pace | Pending |
| Multiple intervals | One saved activity, one lap per interval; resting does not inflate FIT running timer | Pending |
| Personal best | Only a longer eligible interval improves its own pace-level record; other levels are unchanged | Pending |
| Never reach target | History keeps the interval, but it does not set a personal best | Pending |
| History open during automatic stop | No out-of-range errors; interval/rest logic and alerts continue | Pending |
| Exit/relaunch | Best records and interval/rest history persist | Pending |
| Storage bound | More than 40 intervals retains only the most recent 40; best records persist | Pending |
| Round-screen layout | No clipped/overlapping labels on 240px and 260px screens, including alerts and long timers | Pending |
| Sound disabled / vibration disabled | Visual state still conveys the stop/rest transition | Pending |
| FIT save failure, if reproducible | App-local records remain; app reports the failure and allows retry rather than silently losing the activity | Pending |
| Garmin Connect sync | Saved activity, laps, and timing appear as expected; app-local rest history remains available | Pending |

Screenshots to capture from the final build: pace selection, running, rest, and history. Use non-sensitive test activity data.

Final result: __________________. Date: __________________.

1.0.1 retest: check that a fresh weak GPS fix permits START without a speed value; weak GPS must not trigger slow-stop or set a personal best. Check UP/DOWN running-page navigation, live heart rate, no-data -- display, total time excluding rest, clock time, and return to the first page when stopping.
