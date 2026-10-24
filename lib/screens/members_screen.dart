import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_data_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/member_card.dart';
import '../widgets/empty_state.dart';
import 'member_profile_screen.dart';
import 'add_edit_member_screen.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppDataProvider>();
    _searchController.text = provider.searchQuery;
    _searchController.addListener(() {
      provider.setSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildFilterChip(String label, String currentFilter, ValueChanged<String> onSelected) {
    final isSelected = currentFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onSelected(label),
        selectedColor: AppTheme.primaryContainer.withValues(alpha: 0.25),
        backgroundColor: AppTheme.surfaceContainer,
        side: BorderSide(
          color: isSelected ? AppTheme.primary : AppTheme.outlineVariant.withValues(alpha: 0.5),
        ),
        labelStyle: AppTheme.labelSm.copyWith(
          color: isSelected ? AppTheme.primary : AppTheme.onSurfaceVariant,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          letterSpacing: 0,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppDataProvider>(
      builder: (context, provider, _) {
        final filteredList = provider.filteredMembers;
        final totalMembers = provider.allJoinedMembers.length;

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: Column(
            children: [
              // Header & Search bar section
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                color: AppTheme.surface,
                child: Column(
                  children: [
                    // Search bar
                    TextField(
                      controller: _searchController,
                      style: AppTheme.bodyMd.copyWith(color: AppTheme.onSurface),
                      decoration: InputDecoration(
                        hintText: 'Search by name, mobile, or member ID...',
                        hintStyle: AppTheme.bodyMd.copyWith(
                          color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppTheme.onSurfaceVariant,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: AppTheme.surfaceContainerLowest,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          borderSide: const BorderSide(color: AppTheme.outlineVariant),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          borderSide: const BorderSide(color: AppTheme.outlineVariant),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Filter chips row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('All', provider.selectedStatusFilter, provider.setStatusFilter),
                          _buildFilterChip('Active', provider.selectedStatusFilter, provider.setStatusFilter),
                          _buildFilterChip('Expiring Soon', provider.selectedStatusFilter, provider.setStatusFilter),
                          _buildFilterChip('Expired', provider.selectedStatusFilter, provider.setStatusFilter),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content Area
              Expanded(
                child: provider.isMembersLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppTheme.primary),
                      )
                    : totalMembers == 0
                        ? EmptyState(
                            title: 'No members added yet',
                            subtitle: 'Tap the + button below to add your first gym member.',
                            icon: Icons.person_add_alt_1_outlined,
                            actionLabel: 'Add First Member',
                            onAction: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AddEditMemberScreen(),
                                ),
                              );
                            },
                          )
                        : filteredList.isEmpty
                            ? EmptyState(
                                title: 'No matching members',
                                subtitle: 'No members found matching "${_searchController.text}" or current filter.',
                                icon: Icons.search_off,
                              )
                            : RefreshIndicator(
                                onRefresh: () => provider.loadMembers(),
                                color: AppTheme.primary,
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: filteredList.length,
                                  itemBuilder: (context, index) {
                                    final jm = filteredList[index];
                                    return MemberCard(
                                      joinedMember: jm,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => MemberProfileScreen(
                                              memberId: jm.member.memberId,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddEditMemberScreen(),
                ),
              );
            },
            backgroundColor: AppTheme.primary,
            foregroundColor: AppTheme.onPrimary,
            icon: const Icon(Icons.add),
            label: Text(
              'Add Member',
              style: AppTheme.labelSm.copyWith(color: AppTheme.onPrimary),
            ),
          ),
        );
      },
    );
  }
}
