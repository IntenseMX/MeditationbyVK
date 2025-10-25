import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/category_provider.dart';
import '../../../services/category_service.dart';
import 'package:go_router/go_router.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  final TextEditingController _newName = TextEditingController();
  bool _isSavingOrder = false;
  List<CategoryItem>? _localOrder;

  @override
  void dispose() {
    _newName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final actions = ref.watch(categoryActionsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Admin',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
        title: const Text('Categories'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: categoriesAsync.when(
              data: (items) {
                // If we have a local override and the stream now matches it, clear it post-frame
                if (_localOrder != null && _localOrder!.length == items.length) {
                  bool idsMatch = true;
                  for (int i = 0; i < items.length; i++) {
                    if (_localOrder![i].id != items[i].id) {
                      idsMatch = false;
                      break;
                    }
                  }
                  if (idsMatch) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Future.delayed(const Duration(milliseconds: 180), () {
                        if (!mounted) return;
                        setState(() {
                          _localOrder = null;
                          _isSavingOrder = false;
                        });
                      });
                    });
                  }
                }

                final visible = _localOrder ?? items;

                return Stack(
                  children: [
                    CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _newName,
                                  decoration: const InputDecoration(
                                    labelText: 'New category name',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              IntrinsicWidth(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final name = _newName.text.trim();
                                    if (name.isEmpty) return;
                                    await actions.create(name);
                                    _newName.clear();
                                  },
                                  child: const Text('Create'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 16)),
                        if (visible.isEmpty)
                          SliverToBoxAdapter(
                            child: Center(
                              child: Text('No categories yet.', style: TextStyle(color: AppTheme.softCharcoal)),
                            ),
                          )
                        else
                          SliverReorderableList(
                            itemCount: visible.length,
                            proxyDecorator: (child, index, animation) {
                          final theme = Theme.of(context);
                          return Material(
                            elevation: 6,
                            color: theme.cardColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: child,
                          );
                            },
                            itemBuilder: (context, index) {
                              final c = visible[index];
                              return Container(
                                key: ValueKey(c.id),
                                child: ListTile(
                                  title: Text(c.name, style: TextStyle(color: AppTheme.softCharcoal)),
                                  subtitle: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 150),
                                    switchInCurve: Curves.easeOut,
                                    switchOutCurve: Curves.easeIn,
                                    child: DefaultTextStyle.merge(
                                      style: TextStyle(color: AppTheme.richTaupe),
                                      child: _buildOrderSubtitle(index, c.order),
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      PopupMenuButton<String>(
                                        onSelected: (value) async {
                                          switch (value) {
                                            case 'rename':
                                              final newName = await _promptRename(context, c.name);
                                              if (newName != null && newName.trim().isNotEmpty) {
                                                await actions.rename(c.id, newName.trim());
                                              }
                                              break;
                                            case 'archive':
                                              await actions.archive(c.id, archive: true);
                                              break;
                                          }
                                        },
                                        itemBuilder: (context) => const [
                                          PopupMenuItem(
                                            value: 'rename',
                                            child: Text('Rename'),
                                          ),
                                          PopupMenuItem(
                                            value: 'archive',
                                            child: Text('Archive'),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 8),
                                      MouseRegion(
                                        cursor: SystemMouseCursors.grab,
                                        child: ReorderableDragStartListener(
                                          index: index,
                                          child: const SizedBox(
                                            width: 32,
                                            height: 32,
                                            child: Icon(Icons.drag_handle),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            onReorder: (oldIndex, newIndex) async {
                              if (_isSavingOrder) return;
                              setState(() => _isSavingOrder = true);
                              final working = [...visible];
                              if (newIndex > oldIndex) newIndex -= 1;
                              final moved = working.removeAt(oldIndex);
                              working.insert(newIndex, moved);
                              setState(() => _localOrder = working);
                              await actions.reorder(working);
                              // Wait for stream to reflect before clearing local order
                            },
                          ),
                      ],
                    ),
                    if (_isSavingOrder)
                      const Positioned(
                        top: 8,
                        right: 8,
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                  ],
                );
              },
              loading: () => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [
                  SizedBox(height: 16),
                  Expanded(child: Center(child: CircularProgressIndicator())),
                ],
              ),
              error: (e, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  Center(child: Text('Error: $e')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSubtitle(int index, int backendOrder) {
    // While saving or using local order, show a stable index-based label to avoid jumps
    if (_localOrder != null || _isSavingOrder) {
      return Text('order: ${index + 1}', key: const ValueKey('localOrder'));
    }
    return Text('order: $backendOrder', key: const ValueKey('remoteOrder'));
  }

  Future<String?> _promptRename(BuildContext context, String current) async {
    final controller = TextEditingController(text: current);
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename Category'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}


