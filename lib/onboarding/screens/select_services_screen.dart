// lib/onboarding/screens/select_services_screen.dart (COMPLETE CORRECTED CODE)
import 'package:flutter/material.dart';
import 'package:apna_thekedar_specialist/api/api_service.dart';
import 'package:apna_thekedar_specialist/main_nav_screen.dart';
import 'dart:convert';
import 'package:iconsax/iconsax.dart';
import 'dart:io'; // Sirf SocketException ke liye
import 'package:apna_thekedar_specialist/core/widgets/attractive_error_widget.dart';

// Long Project Skills ke liye model
class ServiceCategoryGroup {
  final int categoryId;
  final String categoryName;
  final List<dynamic> services;

  ServiceCategoryGroup({
    required this.categoryId,
    required this.categoryName,
    required this.services,
  });
}

// Short Service Skills ke liye model
class ShortServiceCategoryGroup {
  final int categoryId;
  final String categoryName;
  final List<dynamic> subServices;

  ShortServiceCategoryGroup({
    required this.categoryId,
    required this.categoryName,
    required this.subServices,
  });
}

class SelectServicesScreen extends StatefulWidget {
  final bool isUpdating;
  const SelectServicesScreen({super.key, this.isUpdating = false});

  @override
  _SelectServicesScreenState createState() => _SelectServicesScreenState();
}

class _SelectServicesScreenState extends State<SelectServicesScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _errorType;
  late TabController _tabController;

  List<ServiceCategoryGroup> _groupedLongServices = [];
  List<ShortServiceCategoryGroup> _groupedShortServices = [];
  
  final Set<int> _selectedLongSkillIds = {};
  final Set<int> _selectedShortSkillIds = {};

  final Map<int, String> _longSkillStatusMap = {};
  final Map<int, String> _shortSkillStatusMap = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    setState(() {
      _isLoading = true;
      _errorType = null;
    });

    try {
      // === YAHAN SE 'InternetAddress.lookup' CHECK HATA DIYA GAYA HAI ===

      // 3 APIs ko ek saath call karein
      final responses = await Future.wait([
        _apiService.get('/services/service-connections/'), // Long services
        _apiService.get('/services/short-service-categories/'), // Short services
        if (widget.isUpdating) _apiService.get('/specialist/skills/') // Selected skills
      ]);

      if (mounted) {
        // Response 1: Long Services
        final servicesResponse = responses[0];
        if (servicesResponse.statusCode == 200) {
          final List<dynamic> allServices = json.decode(servicesResponse.body);
          final Map<int, ServiceCategoryGroup> tempMap = {};
          for (var service in allServices) {
            final categoryId = service['category'];
            final categoryName = service['category_name'];
            if (!tempMap.containsKey(categoryId)) {
              tempMap[categoryId] = ServiceCategoryGroup(
                categoryId: categoryId,
                categoryName: categoryName,
                services: [],
              );
            }
            tempMap[categoryId]!.services.add(service);
          }
          tempMap.forEach((key, group) {
            group.services.sort((a, b) => (a['is_default'] ?? false) ? -1 : 1);
          });
          _groupedLongServices = tempMap.values.toList();
        } else {
          // Agar API fail ho, toh error throw karein
          throw Exception('Failed to load long services: ${servicesResponse.body}');
        }

        // Response 2: Short Services
        final shortServicesResponse = responses[1];
        if (shortServicesResponse.statusCode == 200) {
          final List<dynamic> allShortServices = json.decode(shortServicesResponse.body);
          _groupedShortServices = allShortServices.map((category) {
            return ShortServiceCategoryGroup(
              categoryId: category['id'],
              categoryName: category['name'],
              subServices: category['sub_services'] ?? [],
            );
          }).toList();
        } else {
          // Agar API fail ho, toh error throw karein
          throw Exception('Failed to load short services: ${shortServicesResponse.body}');
        }
        
        // Response 3: Selected Skills (agar updating hai)
        if (widget.isUpdating) {
          // Agar updating hai, toh response list mein 3 items honge
          if (responses.length < 3) throw Exception('Skills response missing');
          
          final skillsResponse = responses[2];
          if (skillsResponse.statusCode == 200) {
            final Map<String, dynamic> specialistSkills = json.decode(skillsResponse.body);
            
            final List<dynamic> longSkills = specialistSkills['long_project_skills'] ?? [];
            for (var skill in longSkills) {
              _selectedLongSkillIds.add(skill['skill_id']);
              _longSkillStatusMap[skill['skill_id']] = skill['status'];
            }
            
            final List<dynamic> shortSkills = specialistSkills['short_service_skills'] ?? [];
            for (var skill in shortSkills) {
              _selectedShortSkillIds.add(skill['skill_id']);
              _shortSkillStatusMap[skill['skill_id']] = skill['status'];
            }
          } else {
             throw Exception('Failed to load skills: ${skillsResponse.body}');
          }
        }
      }
    } on SocketException catch (_) {
      // Agar API call fail hoti hai (internet nahi hai ya server band hai)
      _errorType = 'no_internet';
    } catch (e) {
      // Koi aur error
      print("Error in _fetchInitialData: $e");
      if (mounted) _errorType = 'server_error';
    }
    
    if (mounted) setState(() { _isLoading = false; });
  }

  Future<void> _saveSkills() async {
     if (_selectedLongSkillIds.isEmpty && _selectedShortSkillIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one skill from either category.')),
      );
      return;
    }
    setState(() => _isLoading = true);
    
    try {
        final response = await _apiService.post('/specialist/skills/update/', {
            'long_skill_ids': _selectedLongSkillIds.toList(),
            'short_skill_ids': _selectedShortSkillIds.toList(),
        });

        if(mounted){
            if(response.statusCode == 200){
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(widget.isUpdating ? 'Skills updated successfully!' : 'Your profile is complete! Welcome aboard.')),
                );
                if (widget.isUpdating) {
                  Navigator.of(context).pop();
                } else {
                  Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const MainNavScreen()),
                      (route) => false,
                  );
                }
            } else {
                 ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${response.body}')),
                );
            }
        }
    } catch(e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An error occurred: $e')));
    }
    if(mounted) setState(() => _isLoading = false);
  }

  void _onLongSkillSelected(bool? selected, dynamic tappedSkill, ServiceCategoryGroup categoryGroup) {
    setState(() {
      if (selected!) {
        _selectedLongSkillIds.add(tappedSkill['id']);
      } else {
        _selectedLongSkillIds.remove(tappedSkill['id']);
      }
      if (categoryGroup.services.length > 1) {
        final defaultService = categoryGroup.services.firstWhere((s) => s['is_default'] == true, orElse: () => null);
        if (defaultService != null) {
          bool anyNonDefaultSelected = categoryGroup.services.any((s) => s['is_default'] == false && _selectedLongSkillIds.contains(s['id']));
          if (anyNonDefaultSelected) {
            _selectedLongSkillIds.add(defaultService['id']);
          } else {
            if (_longSkillStatusMap[defaultService['id']] != 'APPROVED') {
                _selectedLongSkillIds.remove(defaultService['id']);
            }
          }
        }
      }
    });
  }
  
  void _onShortSkillSelected(bool? selected, dynamic tappedSkill) {
    setState(() {
      final skillId = tappedSkill['id'];
      if (selected!) {
        _selectedShortSkillIds.add(skillId);
      } else {
        _selectedShortSkillIds.remove(skillId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isUpdating ? 'Manage Your Skills' : 'Select Your Skills'),
        automaticallyImplyLeading: widget.isUpdating,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Long Projects'),
            Tab(text: 'Short Services'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorType != null
              ? AttractiveErrorWidget(
                  imagePath: _errorType == 'no_internet' ? 'assets/no_internet.png' : 'assets/server_error.png',
                  title: _errorType == 'no_internet' ? "No Internet" : "Could not load",
                  message: "We couldn't load the list of services. Please check your connection and try again.",
                  buttonText: "Retry",
                  onRetry: _fetchInitialData,
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLongServicesList(),
                    _buildShortServicesList(),
                  ],
                ),
      bottomNavigationBar: (_isLoading || _errorType != null)
      ? null
      : Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveSkills,
            child: _isLoading 
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3,))
              : Text(widget.isUpdating ? 'Update Skills' : 'Finish Setup'),
          ),
        ),
    );
  }

  Widget _buildLongServicesList() {
    if (_groupedLongServices.isEmpty) {
      return const Center(child: Text('No long projects available.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _groupedLongServices.length,
      itemBuilder: (context, index) {
        final categoryGroup = _groupedLongServices[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            leading: const Icon(Iconsax.category, color: Color(0xFF4B2E1E)),
            title: Text(
              categoryGroup.categoryName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            initiallyExpanded: categoryGroup.services.any((s) => _selectedLongSkillIds.contains(s['id'])),
            children: categoryGroup.services.map<Widget>((skill) {
              final skillId = skill['id'];
              final status = _longSkillStatusMap[skillId];
              final bool isApproved = status == 'APPROVED';
              bool isDefault = skill['is_default'] ?? false;
              bool shouldBeDim = isDefault && categoryGroup.services.length > 1;

              return Opacity(
                opacity: (shouldBeDim || isApproved) ? 0.6 : 1.0,
                child: CheckboxListTile(
                  title: Text(skill['sub_service_name']),
                  subtitle: isDefault 
                    ? const Text('(Covers all basic tasks)') 
                    : (isApproved ? const Text('Verified', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)) : null),
                  value: _selectedLongSkillIds.contains(skillId),
                  onChanged: (shouldBeDim || isApproved) ? null : (bool? selected) {
                    _onLongSkillSelected(selected, skill, categoryGroup);
                  },
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildShortServicesList() {
     if (_groupedShortServices.isEmpty) {
      return const Center(child: Text('No short services available.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _groupedShortServices.length,
      itemBuilder: (context, index) {
        final categoryGroup = _groupedShortServices[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            leading: const Icon(Iconsax.flash_1, color: Color(0xFF4B2E1E)),
            title: Text(
              categoryGroup.categoryName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            initiallyExpanded: categoryGroup.subServices.any((s) => _selectedShortSkillIds.contains(s['id'])),
            children: categoryGroup.subServices.map<Widget>((skill) {
              final skillId = skill['id'];
              final status = _shortSkillStatusMap[skillId];
              final bool isApproved = status == 'APPROVED';

              return Opacity(
                opacity: isApproved ? 0.6 : 1.0,
                child: CheckboxListTile(
                  title: Text(skill['name']),
                  subtitle: isApproved ? const Text('Verified', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)) : null,
                  value: _selectedShortSkillIds.contains(skillId),
                  onChanged: isApproved ? null : (bool? selected) {
                    _onShortSkillSelected(selected, skill);
                  },
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}