enum WebSocketMode {
  receiveOnly,
  sendOnly,
  twoWay;

  bool get isReceiveOnly => this == WebSocketMode.receiveOnly;
  bool get isSendOnly => this == WebSocketMode.sendOnly;
  bool get isTwoWay => this == WebSocketMode.twoWay;

  bool get canOverrideRequestBody => isTwoWay || isSendOnly;
}
