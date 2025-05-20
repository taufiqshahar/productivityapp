import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/note_provider.dart';
import 'new_note_screen.dart';
import '../../widgets/custom_app_bar.dart';
import 'dart:async';

class NoteHubScreen extends StatefulWidget {
  final bool openAddDialog;
  const NoteHubScreen({super.key, this.openAddDialog = false});

  @override
  State<NoteHubScreen> createState() => _NoteHubScreenState();
}

class _NoteHubScreenState extends State<NoteHubScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String? _snackbarMessage;
  bool _showError = false;
  String? _categoryFilter;
  String _sortBy = "Updated At";

  @override
  void initState() {
    super.initState();
    if (widget.openAddDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _addNewNote(context);
      });
    }
  }

  void _addNewNote(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NewNoteScreen()),
    );
  }

  Map<String, dynamic> _getCategoryIconAndColor(String category) {
    switch (category) {
      case 'School':
        return {'icon': Icons.school, 'color': Colors.blue};
      case 'Reading':
        return {'icon': Icons.book, 'color': Colors.green};
      case 'Work':
        return {'icon': Icons.work, 'color': Colors.red};
      case 'Personal':
        return {'icon': Icons.person, 'color': Colors.purple};
      default:
        return {'icon': Icons.note, 'color': Colors.grey};
    }
  }

  void _showFilterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        String? tempCategory = _categoryFilter;
        String tempSortBy = _sortBy;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Filter & Sort Notes",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Text("Category", style: Theme.of(context).textTheme.titleMedium),
                      Wrap(
                        spacing: 8.0,
                        children: ["All", "School", "Reading", "Work", "Personal"].map((category) {
                          return ChoiceChip(
                            label: Text(category),
                            selected: tempCategory == (category == "All" ? null : category),
                            onSelected: (selected) {
                              if (selected) {
                                setModalState(() {
                                  tempCategory = category == "All" ? null : category;
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      Text("Sort By", style: Theme.of(context).textTheme.titleMedium),
                      Wrap(
                        spacing: 8.0,
                        children: ["Created At", "Updated At", "Title"].map((sortOption) {
                          return ChoiceChip(
                            label: Text(sortOption),
                            selected: tempSortBy == sortOption,
                            onSelected: (selected) {
                              if (selected) {
                                setModalState(() {
                                  tempSortBy = sortOption;
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel"),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _categoryFilter = tempCategory;
                                _sortBy = tempSortBy;
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).elevatedButtonTheme.style?.backgroundColor?.resolve({}),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text("Apply"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Note Hub",
        actions: [
          TextButton(
            onPressed: () => _addNewNote(context),
            child: const Text("New"), // Removed style to use CustomAppBar's dynamic color
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: "Search Notes",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            Provider.of<NoteProvider>(context, listen: false).searchNotes('');
                          },
                        ),
                      ),
                      onChanged: (value) {
                        if (_debounce?.isActive ?? false) _debounce!.cancel();
                        _debounce = Timer(const Duration(milliseconds: 300), () {
                          Provider.of<NoteProvider>(context, listen: false).searchNotes(value);
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Stack(
                      children: [
                        const Icon(Icons.filter_list),
                        if (_categoryFilter != null || _sortBy != "Updated At")
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Text(
                                "!",
                                style: TextStyle(color: Colors.white, fontSize: 10),
                              ),
                            ),
                          ),
                      ],
                    ),
                    onPressed: () => _showFilterModal(context),
                    tooltip: "Filter & Sort",
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Consumer<NoteProvider>(
                  builder: (context, noteProvider, child) {
                    var notes = noteProvider.getSortedNotes(_sortBy);
                    if (_categoryFilter != null) {
                      notes = notes.where((note) => note.category == _categoryFilter).toList();
                    }
                    if (_searchController.text.isNotEmpty) {
                      notes = noteProvider.filteredNotes;
                    }
                    if (notes.isEmpty) {
                      return const Center(child: Text('No notes found'));
                    }
                    return ListView.builder(
                      key: UniqueKey(),
                      itemCount: notes.length,
                      itemBuilder: (context, index) {
                        final note = notes[index];
                        final iconData = _getCategoryIconAndColor(note.category);
                        return ListTile(
                          key: ValueKey(note.id),
                          leading: Icon(
                            iconData['icon'],
                            color: iconData['color'],
                          ),
                          title: Row(
                            children: [
                              Expanded(child: Text(note.title)),
                              const SizedBox(width: 8),
                              Chip(
                                label: Text(
                                  note.category,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                backgroundColor: Theme.of(context).chipTheme.backgroundColor,
                              ),
                            ],
                          ),
                          subtitle: Text(
                            note.content.isEmpty
                                ? 'No content'
                                : note.content.length > 50
                                ? '${note.content.substring(0, 50)}...'
                                : note.content,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                                  color: note.isPinned ? Colors.blue : null,
                                ),
                                tooltip: note.isPinned ? 'Unpin note' : 'Pin note',
                                onPressed: () async {
                                  try {
                                    await noteProvider.togglePinNote(note);
                                    setState(() {
                                      _snackbarMessage = 'Note ${note.isPinned ? 'pinned' : 'unpinned'} successfully';
                                      _showError = false;
                                    });
                                  } catch (e) {
                                    setState(() {
                                      _snackbarMessage = 'Failed to toggle pin: $e';
                                      _showError = true;
                                    });
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                tooltip: 'Delete note',
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Note'),
                                      content: Text('Are you sure you want to delete "${note.title}"?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    try {
                                      await noteProvider.deleteNote(note);
                                      setState(() {
                                        _snackbarMessage = 'Note deleted successfully';
                                        _showError = false;
                                      });
                                    } catch (e) {
                                      setState(() {
                                        _snackbarMessage = 'Failed to delete note: $e';
                                        _showError = true;
                                      });
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NewNoteScreen(note: note),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant NoteHubScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_snackbarMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_snackbarMessage!),
          backgroundColor: _showError ? Colors.red : null,
        ),
      );
      setState(() {
        _snackbarMessage = null;
        _showError = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }
}