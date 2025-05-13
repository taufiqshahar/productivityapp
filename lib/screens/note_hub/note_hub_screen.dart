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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Note Hub",
        actions: [
          TextButton(
            onPressed: () => _addNewNote(context),
            child: const Text(
              "New",
              style: TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
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
              const SizedBox(height: 8),
              DropdownButton<String>(
                hint: const Text("Filter by Category"),
                value: _categoryFilter,
                items: ["All", "School", "Reading", "Work", "Personal"].map((category) {
                  return DropdownMenuItem<String>(
                    value: category == "All" ? null : category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _categoryFilter = value);
                },
              ),
              const SizedBox(height: 8),
              DropdownButton<String>(
                hint: const Text("Sort by"),
                value: _sortBy,
                items: ["Created At", "Updated At", "Title"].map((sortOption) {
                  return DropdownMenuItem<String>(
                    value: sortOption,
                    child: Text(sortOption),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _sortBy = value ?? "Updated At");
                },
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
                      notes = notes.where((note) {
                        return note.title.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                            note.content.toLowerCase().contains(_searchController.text.toLowerCase());
                      }).toList();
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