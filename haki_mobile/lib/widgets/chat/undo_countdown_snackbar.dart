import 'dart:async';

import 'package:flutter/material.dart';

class UndoCountdownSnackbar extends StatefulWidget {
  final VoidCallback onUndo;

  const UndoCountdownSnackbar({super.key, required this.onUndo});

  @override
  State<UndoCountdownSnackbar> createState() => _UndoCountdownSnackbarState();
}

class _UndoCountdownSnackbarState extends State<UndoCountdownSnackbar> {
  int _secondsLeft = 5;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 1) {
        setState(() => _secondsLeft--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Deleting in $_secondsLeft seconds...',
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
        TextButton(
          onPressed: () {
            widget.onUndo();
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
          child: Text(
            'UNDO',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
