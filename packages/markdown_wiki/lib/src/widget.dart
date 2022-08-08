import 'package:flutter/material.dart';
import 'package:flutter_treeview/flutter_treeview.dart';

import 'resource/resource_manager.dart';

class MarkdownWiki extends StatefulWidget {
  final ResourceManager resourceManager;

  const MarkdownWiki({
    super.key,
    required this.resourceManager,
  });

  @override
  State<MarkdownWiki> createState() => _MarkdownWikiState();
}

class _MarkdownWikiState extends State<MarkdownWiki> {
  late TreeViewController _treeViewController;

  void expandToNode(String key) {
    final updatedNodes = _treeViewController.expandToNode(key);
    setState(() {
      _treeViewController =
          _treeViewController.copyWith(children: updatedNodes);
    });
  }

  @override
  void initState() {
    List<Node> nodes = const [
      Node(
        label: 'Lukas',
        key: 'lukas',
        expanded: true,
        children: [
          Node(
            label: 'Otis',
            key: 'otis',
          ),
          Node(
            label: 'Zorro',
            key: 'zorro',
          ),
        ],
      ),
    ];

    _treeViewController = TreeViewController(
      children: nodes,
    );

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Container(
        child: Row(
          children: [
            SizedBox(
              width: 300.0,
              height: MediaQuery.of(context).size.height,
              child: TreeView(
                controller: _treeViewController,
                onExpansionChanged: (String key, bool state) {
                  Node? node = _treeViewController.getNode(key);
                  if (node != null) {
                    List<Node> updatedNodes = _treeViewController.updateNode(
                        key, node.copyWith(expanded: state));
                    setState(() {
                      _treeViewController =
                          _treeViewController.copyWith(children: updatedNodes);
                    });
                  }
                },
              ),
            ),
            ElevatedButton(
              onPressed: () {
                expandToNode('otis');
              },
              child: const Text('expand'),
            ),
          ],
        ),
      ),
    );
  }
}
