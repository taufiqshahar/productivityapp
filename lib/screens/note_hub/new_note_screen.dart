import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/note.dart';
import '../../providers/note_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/form_field.dart';

class NewNoteScreen extends StatefulWidget {
  final Note? note;

  const NewNoteScreen({super.key, this.note});

  @override
  State<NewNoteScreen> createState() => _NewNoteScreenState();
}

class _NewNoteScreenState extends State<NewNoteScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String? _category;
  bool _isPinned = false;
  Note? _originalNote;

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _originalNote = widget.note;
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
      _category = widget.note!.category;
      _isPinned = widget.note!.isPinned;
    } else {
      _category = "School";
    }
  }

  Future<void> _saveNote() async {
    if (_titleController.text.isNotEmpty &&
        _contentController.text.isNotEmpty &&
        _category != null) {
      try {
        final now = DateTime.now();
        final newNote = Note(
          id: _originalNote?.id ?? '',
          title: _titleController.text,
          content: _contentController.text,
          category: _category!,
          createdAt: _originalNote?.createdAt ?? now,
          updatedAt: now,
          isPinned: _isPinned,
        );
        final noteProvider = Provider.of<NoteProvider>(context, listen: false);
        if (_originalNote != null) {
          await noteProvider.updateNote(_originalNote!, newNote);
        } else {
          await noteProvider.addNote(newNote);
        }
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error saving note: $e")),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _originalNote == null ? "New Note" : "Edit Note",
        showHomeButton: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _originalNote == null ? "New Note" : "Edit Note",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              CustomFormField(
                label: "Note Title",
                hint: "What's the note about?",
                controller: _titleController,
              ),
              const SizedBox(height: 16),
              CustomFormField(
                label: "Content",
                hint: "Write your note here...",
                controller: _contentController,
                maxLines: 5,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: "Category",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                value: _category,
                hint: const Text("Select category"),
                items: ["School", "Reading", "Work", "Personal"].map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _category = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text("Pin this note"),
                value: _isPinned,
                onChanged: (value) {
                  setState(() {
                    _isPinned = value!;
                  });
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black54,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    onPressed: _saveNote,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD1C4E9),
                      foregroundColor: Colors.black87,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(_originalNote == null ? "Save Note" : "Update Note"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}