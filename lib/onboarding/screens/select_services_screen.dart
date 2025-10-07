// lib/onboarding/screens/select_services_screen.dart

import 'package:flutter/material.dart';
import 'package:apna_thekedar_specialist/api/api_service.dart';
import 'package:apna_thekedar_specialist/main_nav_screen.dart'; // Naya import
import 'dart:convert';
import 'package:iconsax/iconsax.dart';

// Service Connections ko aache se manage karne ke liye ek choti si class
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

// Specialist ki select ki hui skill ko manage karne ke liye class
class SpecialistSkill {
  final int skillId;
  final String status;

  SpecialistSkill({required this.skillId, required this.status});
}

class SelectServicesScreen extends StatefulWidget {
  final bool isUpdating;
  const SelectServicesScreen({super.key, this.isUpdating = false});

  @override
  _SelectServicesScreenState createState() => _SelectServicesScreenState();
}
class _SelectServicesScreenState extends State<SelectServicesScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _error;
  List<ServiceCategoryGroup> _groupedServices = [];
  final Set<int> _selectedSkillIds = {};
  final Map<int, String> _skillStatusMap = {}; // Skill ID aur uska status store karega

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    try {
      // Dono APIs ko ek saath call karein
      final responses = await Future.wait([
        _apiService.get('/services/service-connections/'),
        if (widget.isUpdating) _apiService.get('/specialist/skills/')
      ]);

      if (mounted) {
        // Service Connections ka response handle karein
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
            group.services.sort((a, b) {
              bool isADefault = a['is_default'] ?? false;
              bool isBDefault = b['is_default'] ?? false;
              if (isADefault) return -1;
              if (isBDefault) return 1;
              return 0;
            });
          });

          _groupedServices = tempMap.values.toList();
        } else {
          _error = "Failed to load services.";
        }
        
        // Agar updating mode mein hai, toh specialist ki skills ka response handle karein
        if (widget.isUpdating) {
          final skillsResponse = responses[1];
          if (skillsResponse.statusCode == 200) {
            final List<dynamic> specialistSkills = json.decode(skillsResponse.body);
            for (var skill in specialistSkills) {
              _selectedSkillIds.add(skill['skill_id']);
              _skillStatusMap[skill['skill_id']] = skill['status'];
            }
          }
        }
      }
    } catch (e) {
      if (mounted) _error = "An error occurred: $e";
    }
    if (mounted) setState(() { _isLoading = false; });
  }


  void _onSkillSelected(bool? selected, dynamic tappedSkill, ServiceCategoryGroup categoryGroup) {
    setState(() {
      if (selected!) {
        _selectedSkillIds.add(tappedSkill['id']);
      } else {
        _selectedSkillIds.remove(tappedSkill['id']);
      }

      if (categoryGroup.services.length > 1) {
        final defaultService = categoryGroup.services.firstWhere(
          (s) => s['is_default'] == true,
          orElse: () => null,
        );

        if (defaultService != null) {
          bool anyNonDefaultSelected = categoryGroup.services.any(
            (s) => s['is_default'] == false && _selectedSkillIds.contains(s['id'])
          );

          if (anyNonDefaultSelected) {
            _selectedSkillIds.add(defaultService['id']);
          } else {
            // Agar koi bhi non-default skill select nahi hai, toh default ko bhi hata do
             if (_skillStatusMap[defaultService['id']] != 'APPROVED') {
                _selectedSkillIds.remove(defaultService['id']);
            }
          }
        }
      }
    });
  }

  Future<void> _saveSkills() async {
     if (_selectedSkillIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one skill.')),
      );
      return;
    }
    setState(() => _isLoading = true);
    
    try {
        final response = await _apiService.post('/specialist/skills/update/', {
            'skill_ids': _selectedSkillIds.toList(),
        });

        if(mounted){
            if(response.statusCode == 200){
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(widget.isUpdating ? 'Skills updated successfully!' : 'Your profile is complete! Welcome aboard.')),
                );
                // Agar update kar rahe hain toh wapas profile screen par jaayein, warna home par
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
    } catch(e){
        // handle error
    }
    if(mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isUpdating ? 'Manage Your Skills' : 'Select Your Skills'),
        // Onboarding ke time back button nahi hoga
        automaticallyImplyLeading: widget.isUpdating,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _groupedServices.length,
                  itemBuilder: (context, index) {
                    final categoryGroup = _groupedServices[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ExpansionTile(
                        leading: const Icon(Iconsax.category, color: Color(0xFF4B2E1E)),
                        title: Text(
                          categoryGroup.categoryName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        initiallyExpanded: categoryGroup.services.any((s) => _selectedSkillIds.contains(s['id'])),
                        children: categoryGroup.services.map<Widget>((skill) {
                          final skillId = skill['id'];
                          final status = _skillStatusMap[skillId];
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
                              value: _selectedSkillIds.contains(skillId),
                              // Agar skill approved hai, toh use disable kar do
                              onChanged: (shouldBeDim || isApproved) ? null : (bool? selected) {
                                _onSkillSelected(selected, skill, categoryGroup);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
      bottomNavigationBar: Padding(
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
}