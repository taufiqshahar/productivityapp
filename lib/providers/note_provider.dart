import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import '../models/note.dart';

class NoteProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final List<Note> _notes = [];
  final _logger = Logger();
  String _currentQuery = '';

  List<Note> get notes {
    return List.from(_notes)..sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
  }

  // Getter for sorted notes based on the selected criterion
  List<Note> getSortedNotes(String sortBy) {
    final sortedNotes = List<Note>.from(_notes);
    sortedNotes.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      switch (sortBy) {
        case 'Created At':
          return a.createdAt.compareTo(b.createdAt);
        case 'Updated At':
          return b.updatedAt.compareTo(a.updatedAt);
        case 'Title':
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        default:
          return b.updatedAt.compareTo(a.updatedAt);
      }
    });
    return sortedNotes;
  }

  NoteProvider() {
    loadNotes();
  }

  Future<void> loadNotes() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _logger.w('No user is signed in');
        _notes.clear();
        notifyListeners();
        return;
      }
      final snapshot = await _firestore
          .collection('notes')
          .where('userId', isEqualTo: user.uid)
          .get();
      _notes.clear();
      _notes.addAll(snapshot.docs.map((doc) {
        final data = doc.data();
        final title = data['title'] as String? ?? 'Untitled Note';
        final content = data['content'] as String? ?? '';
        final category = data['category'] as String? ?? 'General';
        final isPinned = data['isPinned'] as bool? ?? false;
        DateTime createdAt;
        DateTime updatedAt;
        try {
          createdAt = data['createdAt'] != null
              ? DateTime.parse(data['createdAt'] as String)
              : DateTime.now();
          updatedAt = data['updatedAt'] != null
              ? DateTime.parse(data['updatedAt'] as String)
              : DateTime.now();
        } catch (e) {
          _logger.w('Invalid date format in note ${doc.id}: $e');
          createdAt = DateTime.now();
          updatedAt = DateTime.now();
        }
        return Note(
          id: doc.id,
          title: title,
          content: content,
          createdAt: createdAt,
          updatedAt: updatedAt,
          category: category,
          isPinned: isPinned,
        );
      }).toList());
      notifyListeners();
    } catch (e) {
      _logger.e('Error loading notes: $e');
      rethrow;
    }
  }

  Future<void> addNote(Note note) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _logger.w('No user is signed in');
        return;
      }
      final now = DateTime.now();
      final docRef = await _firestore.collection('notes').add({
        'userId': user.uid,
        'title': note.title,
        'content': note.content,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'category': note.category,
        'isPinned': note.isPinned,
      });
      _notes.add(Note(
        id: docRef.id,
        title: note.title,
        content: note.content,
        createdAt: now,
        updatedAt: now,
        category: note.category,
        isPinned: note.isPinned,
      ));
      notifyListeners();
    } catch (e) {
      _logger.e('Error adding note: $e');
      rethrow;
    }
  }

  Future<void> updateNote(Note oldNote, Note newNote) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _logger.w('No user is signed in');
        return;
      }
      await _firestore.collection('notes').doc(oldNote.id).update({
        'userId': user.uid,
        'title': newNote.title,
        'content': newNote.content,
        'updatedAt': DateTime.now().toIso8601String(),
        'category': newNote.category,
        'isPinned': newNote.isPinned,
      });
      final index = _notes.indexWhere((n) => n.id == oldNote.id);
      if (index != -1) {
        _notes[index] = newNote.copyWith(id: oldNote.id, updatedAt: DateTime.now());
        notifyListeners();
      } else {
        await loadNotes();
      }
    } catch (e) {
      _logger.e('Error updating note: $e');
      rethrow;
    }
  }

  Future<void> deleteNote(Note note) async {
    try {
      await _firestore.collection('notes').doc(note.id).delete();
      _notes.removeWhere((n) => n.id == note.id);
      notifyListeners();
    } catch (e) {
      _logger.e('Error deleting note: $e');
      rethrow;
    }
  }

  Future<void> togglePinNote(Note note) async {
    try {
      final updatedNote = note.copyWith(isPinned: !note.isPinned, updatedAt: DateTime.now());
      await updateNote(note, updatedNote);
      _logger.i('Toggled pin status for note ${note.id} to ${!note.isPinned}');
    } catch (e) {
      _logger.e('Error toggling pin status: $e');
      rethrow;
    }
  }

  void searchNotes(String query) {
    _currentQuery = query;
    notifyListeners();
  }

  List<Note> get filteredNotes {
    var notes = getSortedNotes('Updated At'); // Default to Updated At
    if (_currentQuery.isEmpty) {
      return notes;
    }
    return notes.where((note) {
      return note.title.toLowerCase().contains(_currentQuery.toLowerCase()) ||
          note.content.toLowerCase().contains(_currentQuery.toLowerCase());
    }).toList();
  }
}

extension NoteExtension on Note {
  Note copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? category,
    bool? isPinned,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}