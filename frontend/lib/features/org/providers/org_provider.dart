import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/networking/dio_client.dart';

class OrgItem {
  final int id;
  final String name;
  final int? companyId;
  final String? companyName;
  final bool isActive;
  OrgItem({required this.id, required this.name, this.companyId, this.companyName, this.isActive = true});
  factory OrgItem.fromJson(Map<String, dynamic> j) => OrgItem(
        id: j['id'],
        name: j['name'] ?? '',
        companyId: j['company_id'],
        companyName: (j['company'] as Map<String, dynamic>?)?['name'] as String?,
        isActive: j['is_active'] ?? true,
      );
}

// Companies
final companiesProvider = FutureProvider<List<OrgItem>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get(ApiConstants.companies);
  final List data = res.data['data'] ?? [];
  return data.map((j) => OrgItem.fromJson(j)).toList();
});

// Departments
final departmentsProvider = FutureProvider.family<List<OrgItem>, int?>((ref, companyId) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get(ApiConstants.departments,
      queryParameters: companyId != null ? {'company_id': companyId} : null);
  final List data = res.data['data'] ?? [];
  return data.map((j) => OrgItem.fromJson(j)).toList();
});

// Locations
final locationsProvider = FutureProvider.family<List<OrgItem>, int?>((ref, companyId) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get(ApiConstants.locations,
      queryParameters: companyId != null ? {'company_id': companyId} : null);
  final List data = res.data['data'] ?? [];
  return data.map((j) => OrgItem.fromJson(j)).toList();
});

// All users (for task assignment dropdown)
final allUsersProvider = FutureProvider<List<OrgItem>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/users', queryParameters: {'limit': 500});
  final List data = res.data['data']['users'] ?? [];
  return data
      .map((j) => OrgItem(
            id: j['id'],
            name: '${j['name'] ?? ''} (${j['role'] ?? ''})',
            companyId: j['company_id'],
          ))
      .toList();
});

// Managers dropdown — only users who can manage others
final managersDropdownProvider = FutureProvider<List<OrgItem>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/users', queryParameters: {'limit': 500});
  final List data = res.data['data']['users'] ?? [];
  const managerRoles = {'manager', 'department_head', 'management', 'superadmin'};
  return data
      .where((j) => managerRoles.contains(j['role']))
      .map((j) => OrgItem(id: j['id'], name: j['name'] ?? '', companyId: j['company_id']))
      .toList();
});

// Department heads dropdown — department_head / management / superadmin only
final deptHeadsDropdownProvider = FutureProvider<List<OrgItem>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/users', queryParameters: {'limit': 500});
  final List data = res.data['data']['users'] ?? [];
  const headRoles = {'department_head', 'management', 'superadmin'};
  return data
      .where((j) => headRoles.contains(j['role']))
      .map((j) => OrgItem(id: j['id'], name: j['name'] ?? '', companyId: j['company_id']))
      .toList();
});
