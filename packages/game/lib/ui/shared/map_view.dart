import 'package:flutter/material.dart';

class InteractiveView extends StatefulWidget {
  const InteractiveView({Key? key}) : super(key: key);

  @override
  _InteractiveViewState createState() => _InteractiveViewState();
}

class _InteractiveViewState extends State<InteractiveView>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _transformationController = TransformationController();

  Animation<Matrix4>? _resetAnimation;

  AnimationController? _resetController;

  final _latitudeTextFieldController = TextEditingController();
  final _longitudeTextFieldController = TextEditingController();

  // Size _viewSize;

  Future<void> _showLocationDialog(BuildContext context,
      {void Function(double, double)? dismissCallback}) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Dialog'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: _latitudeTextFieldController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Latitude',
                  ),
                ),
                TextField(
                  controller: _longitudeTextFieldController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Longitude',
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Go!'),
              onPressed: () {
                Navigator.of(context).pop();
                if (dismissCallback != null) {
                  var lat =
                      double.tryParse(_latitudeTextFieldController.text) ?? 0.0;
                  var long =
                      double.tryParse(_longitudeTextFieldController.text) ??
                          0.0;
                  dismissCallback(lat, long);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _setLocation(double x, double y) {
    _animateMovingInitialize(end: Matrix4.translationValues(-x, -y, 0));
  }

  void _onAnimateReset() {
    _transformationController.value = _resetAnimation!.value;
    if (!_resetController!.isAnimating) {
      _resetAnimation?.removeListener(_onAnimateReset);
      _resetAnimation = null;
      _resetController!.reset();
    }
  }

  void _animateMovingInitialize({Matrix4? end}) {
    end ??= Matrix4.identity();
    _resetController!.reset();
    _resetAnimation = Matrix4Tween(
      begin: _transformationController.value,
      end: end,
    ).animate(_resetController!);
    _resetAnimation!.addListener(_onAnimateReset);
    _resetController!.forward();
  }

// Stop a running reset to home transform animation.
  void _animateResetStop() {
    _resetController!.stop();
    _resetAnimation?.removeListener(_onAnimateReset);
    _resetAnimation = null;
    _resetController!.reset();
  }

  void _onInteractionStart(ScaleStartDetails details) {
    // If the user tries to cause a transformation while the reset animation is
    // running, cancel the reset animation.
    if (_resetController!.status == AnimationStatus.forward) {
      _animateResetStop();
    }
  }

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _resetController?.dispose();
    _latitudeTextFieldController.dispose();
    _longitudeTextFieldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // _viewSize = Size(constraints.minWidth, constraints.minHeight);

        var widgets = <Widget>[
          InteractiveViewer(
            transformationController: _transformationController,
            onInteractionStart: _onInteractionStart,
            minScale: 0.1,
            maxScale: 1.0,
            child: const Image(image: AssetImage("assets/images/hediguo.png")),
            constrained: false,
          ),
          Positioned(
            right: 25,
            top: 25,
            child: IconButton(
              onPressed: _animateMovingInitialize,
              icon: const Icon(
                Icons.replay,
              ),
            ),
          ),
          Positioned(
            right: 25,
            top: 85,
            child: IconButton(
              onPressed: () =>
                  _showLocationDialog(context, dismissCallback: _setLocation),
              icon: const Icon(
                Icons.edit_location,
              ),
            ),
          ),
          Positioned(
            right: 25,
            top: 145,
            child: IconButton(
              onPressed: () => showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    content: Text(
                      _transformationController.value.toString(),
                      style: Theme.of(context).textTheme.bodyText2,
                    ),
                  );
                },
              ),
              icon: const Icon(
                Icons.question_answer,
              ),
            ),
          ),
        ];

        return Stack(children: widgets);
      },
    );
  }
}
