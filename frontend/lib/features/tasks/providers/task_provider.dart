import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/networking/dio_client.dart';

class TaskListState {
  final List<TaskModel> tasks;
  final bool isLoading;
  final String? error;
  final int page;
  final bool hasMore;

  const TaskListState({
    this.tasks = const [],
    this.isLoading = false,
    this.error,
    this.page = 1,
    this.hasMore = true,
  });

  TaskListState copyWith({
    List<TaskModel>? tasks,
    bool? isLoading,
    String? error,
    int? page,
    bool? hasMore,
  }) {
    return TaskListState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class TaskNotifier extends Notifier<TaskListState> {
  @override
  TaskListState build() {
    fetchTasks();
    return const TaskListState();
  }

  Dio get _dio => ref.read(dioProvider);

  Future<void> fetchTasks({Map<String, dynamic>? filters, bool reset = false}) async {
    if (state.isLoading) return;

    final page = reset ? 1 : state.page;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _dio.get(
        ApiConstants.tasks,
        queryParameters: {
          'page': page,
          'limit': 20,
          ...?filters,
        },
      );

      final List data = response.data['data']['tasks'];
      final tasks = data.map((j) => TaskModel.fromJson(j)).toList();
      final total = response.data['data']['total'] as int;
      final allTasks = reset ? tasks : [...state.tasks, ...tasks];

      state = state.copyWith(
        tasks: allTasks,
        isLoading: false,
        page: page + 1,
        hasMore: allTasks.length < total,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['message'] ?? 'Failed to load tasks',
      );
    }
  }

  Future<TaskModel?> getTask(int id) async {
    try {
      final response = await _dio.get(ApiConstants.taskById(id));
      return TaskModel.fromJson(response.data['data']);
    } on DioException {
      return null;
    }
  }

  Future<bool> createTask(Map<String, dynamic> data) async {
    try {
      await _dio.post(ApiConstants.tasks, data: data);
      await fetchTasks(reset: true);
      return true;
    } on DioException {
      return false;
    }
  }

  Future<bool> updateTask(int id, Map<String, dynamic> data) async {
    try {
      await _dio.put(ApiConstants.taskById(id), data: data);
      await fetchTasks(reset: true);
      return true;
    } on DioException {
      return false;
    }
  }

  Future<bool> deleteTask(int id) async {
    try {
      await _dio.delete(ApiConstants.taskById(id));
      state = state.copyWith(
        tasks: state.tasks.where((t) => t.id != id).toList(),
      );
      return true;
    } on DioException {
      return false;
    }
  }

  Future<bool> submitReview(int id, Map<String, dynamic> data) async {
    try {
      await _dio.post(ApiConstants.taskReview(id), data: data);
      await fetchTasks(reset: true);
      return true;
    } on DioException {
      return false;
    }
  }

  Future<List<TaskActivity>> getTaskActivities(int id) async {
    try {
      final response = await _dio.get(ApiConstants.taskActivities(id));
      final List data = response.data['data'] ?? [];
      return data.map((j) => TaskActivity.fromJson(j)).toList();
    } on DioException {
      return [];
    }
  }
}

final taskProvider = NotifierProvider<TaskNotifier, TaskListState>(TaskNotifier.new);
