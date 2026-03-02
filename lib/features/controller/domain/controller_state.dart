class ControllerState {
  final int lx, ly, rx, ry; // int16
  final int l2, r2;         // uint8 0..255
  final int dpadX, dpadY;   // int8 -1..1
  final int buttons;        // uint32 bitmask
  final int seq;

  const ControllerState({
    required this.lx,
    required this.ly,
    required this.rx,
    required this.ry,
    required this.l2,
    required this.r2,
    required this.dpadX,
    required this.dpadY,
    required this.buttons,
    required this.seq,
  });

  factory ControllerState.neutral() => const ControllerState(
    lx: 0, ly: 0, rx: 0, ry: 0,
    l2: 0, r2: 0,
    dpadX: 0, dpadY: 0,
    buttons: 0,
    seq: 0,
  );

  ControllerState copyWith({
    int? lx, int? ly, int? rx, int? ry,
    int? l2, int? r2,
    int? dpadX, int? dpadY,
    int? buttons,
    int? seq,
  }) {
    return ControllerState(
      lx: lx ?? this.lx,
      ly: ly ?? this.ly,
      rx: rx ?? this.rx,
      ry: ry ?? this.ry,
      l2: l2 ?? this.l2,
      r2: r2 ?? this.r2,
      dpadX: dpadX ?? this.dpadX,
      dpadY: dpadY ?? this.dpadY,
      buttons: buttons ?? this.buttons,
      seq: seq ?? this.seq,
    );
  }
}