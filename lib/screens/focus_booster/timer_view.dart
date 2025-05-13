import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:vibration/vibration.dart';
import '../../providers/focus_provider.dart';
import '../../models/focus_session.dart';
import '../../utils/constants.dart';

class TimerView extends StatefulWidget {
  const TimerView({super.key});

  @override
  State<TimerView> createState() => _TimerViewState();
}

class _TimerViewState extends State<TimerView> with SingleTickerProviderStateMixin {
  Timer? _timer;
  Timer? _quoteTimer;
  int _secondsRemaining = 25 * 60;
  bool _isRunning = false;
  bool _isPaused = false;
  int _sessionDurationMinutes = 25;
  int _selectedDuration = 25;
  bool _isBreak = false;
  int _pomodoroCycleCount = 0;
  static const int _breakDurationMinutes = 5;
  static const int _longBreakDurationMinutes = 15;
  static const int _cyclesForLongBreak = 4;

  AnimationController? _animationController;
  Animation<double>? _scaleAnimation;
  String _currentQuote = AppConstants.motivationalQuotes[0];
  int _quoteIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut),
    );
    _secondsRemaining = _selectedDuration * 60;
    _updateQuote();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _quoteTimer?.cancel();
    _animationController?.dispose();
    super.dispose();
  }

  void _updateQuote() {
    setState(() {
      _currentQuote = AppConstants.motivationalQuotes[_quoteIndex];
      _quoteIndex = (_quoteIndex + 1) % AppConstants.motivationalQuotes.length;
    });
  }

  void _startSession() {
    if (!_isRunning) {
      setState(() {
        _isRunning = true;
        _isPaused = false;
        _sessionDurationMinutes = _isBreak ? _breakDurationMinutes : _selectedDuration;
        if (_isBreak && _pomodoroCycleCount % _cyclesForLongBreak == 0 && _pomodoroCycleCount > 0) {
          _sessionDurationMinutes = _longBreakDurationMinutes;
        }
        _secondsRemaining = _sessionDurationMinutes * 60;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
          } else {
            _timer?.cancel();
            _endSession(autoCompleted: true);
          }
        });
      });
      _quoteTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
        _updateQuote();
      });
      _animationController?.forward();
    }
  }

  void _pauseSession() {
    if (_isRunning && !_isPaused) {
      _timer?.cancel();
      _quoteTimer?.cancel();
      setState(() {
        _isPaused = true;
      });
      _animationController?.reverse();
    }
  }

  void _resumeSession() {
    if (_isRunning && _isPaused) {
      setState(() {
        _isPaused = false;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
          } else {
            _timer?.cancel();
            _endSession(autoCompleted: true);
          }
        });
      });
      _quoteTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
        _updateQuote();
      });
      _animationController?.forward();
    }
  }

  void _stopSession() {
    _timer?.cancel();
    _quoteTimer?.cancel();
    _endSession(autoCompleted: false);
  }

  void _resetSession() {
    _timer?.cancel();
    _quoteTimer?.cancel();
    setState(() {
      _secondsRemaining = _selectedDuration * 60;
      _isRunning = false;
      _isPaused = false;
      _isBreak = false;
      _pomodoroCycleCount = 0;
      _sessionDurationMinutes = _selectedDuration;
      _quoteIndex = 0;
      _updateQuote();
    });
    _animationController?.reverse();
  }

  void _endSession({required bool autoCompleted}) async {
    _timer?.cancel();
    _quoteTimer?.cancel();
    if (!_isBreak) {
      final durationMinutes = autoCompleted
          ? _sessionDurationMinutes
          : (_sessionDurationMinutes - (_secondsRemaining ~/ 60)).clamp(0, _sessionDurationMinutes);

      if (durationMinutes > 0) {
        final session = FocusSession(
          date: DateTime.now(),
          durationMinutes: durationMinutes,
        );
        await Provider.of<FocusProvider>(context, listen: false).addSession(session).then((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Focus session saved: $durationMinutes minutes')),
            );
          }
        }).catchError((error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error saving session: $error')),
            );
          }
        });
      }

      setState(() {
        _pomodoroCycleCount++;
        _isBreak = true;
        _isRunning = false;
        _isPaused = false;
      });
    } else {
      setState(() {
        _isBreak = false;
        _isRunning = false;
        _isPaused = false;
      });
    }

    if (autoCompleted) {
      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(duration: 500);
      }
    }

    _animationController?.reverse();
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final double progress = _secondsRemaining / (_sessionDurationMinutes * 60);
    final double remainingProgress = progress.clamp(0.0, 1.0);
    final double elapsedProgress = (1.0 - remainingProgress).clamp(0.0, 1.0);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_isRunning && !_isPaused) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              _currentQuote,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    offset: const Offset(1, 1),
                    blurRadius: 2,
                  ),
                ],
              ) ??
                  const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text(
          _isBreak ? 'Break Time' : 'Work Session #${_pomodoroCycleCount + 1}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: _isBreak ? Colors.green : Colors.blueAccent,
            fontWeight: FontWeight.bold,
          ) ??
              const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (!_isRunning)
          DropdownButton<int>(
            value: _selectedDuration,
            items: [15, 25, 50].map((duration) {
              return DropdownMenuItem<int>(
                value: duration,
                child: Text('$duration minutes'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedDuration = value!;
                _secondsRemaining = _selectedDuration * 60;
                _sessionDurationMinutes = _selectedDuration;
              });
            },
            style: Theme.of(context).textTheme.titleMedium,
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        const SizedBox(height: 24),
        SizedBox(
          height: 250,
          width: 250,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SfCircularChart(
                series: <CircularSeries>[
                  DoughnutSeries<double, String>(
                    dataSource: [
                      remainingProgress,
                      elapsedProgress,
                    ],
                    xValueMapper: (double value, _) => value.toString(),
                    yValueMapper: (double value, _) => value,
                    pointColorMapper: (double value, int index) => index == 0
                        ? (_isBreak ? Colors.green : const Color(0xFFD1C4E9))
                        : Colors.grey.shade200,
                    innerRadius: '80%',
                    radius: '100%',
                    animationDuration: 500,
                  ),
                ],
              ),
              Text(
                _formatTime(_secondsRemaining),
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ) ??
                    const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_isRunning || _isPaused)
              ScaleTransition(
                scale: _scaleAnimation!,
                child: ElevatedButton(
                  onPressed: _isPaused ? _resumeSession : _startSession,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isBreak ? Colors.green : const Color(0xFFD1C4E9),
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text(_isPaused ? 'Resume' : 'Start'),
                ),
              ),
            if (_isRunning && !_isPaused) ...[
              ScaleTransition(
                scale: _scaleAnimation!,
                child: ElevatedButton(
                  onPressed: _pauseSession,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black54,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Pause'),
                ),
              ),
              const SizedBox(width: 16),
            ],
            if (_isRunning || _isPaused) ...[
              ScaleTransition(
                scale: _scaleAnimation!,
                child: ElevatedButton(
                  onPressed: _stopSession,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade100,
                    foregroundColor: Colors.red.shade900,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Stop'),
                ),
              ),
              const SizedBox(width: 16),
            ],
            ScaleTransition(
              scale: _scaleAnimation!,
              child: ElevatedButton(
                onPressed: _resetSession,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.black54,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Reset'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}