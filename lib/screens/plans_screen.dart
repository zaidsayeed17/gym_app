import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/joined_plan.dart';
import '../models/plan.dart';
import '../providers/app_data_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';

class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  void _showAddEditPlanModal(BuildContext context, {Plan? plan}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: plan?.planName ?? '');
    final durationController = TextEditingController(
      text: plan != null ? plan.durationMonths.toString() : '1',
    );
    final priceController = TextEditingController(
      text: plan != null ? plan.price.toStringAsFixed(0) : '500',
    );

    final isEdit = plan != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusXl),
            ),
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEdit ? 'Edit Membership Plan' : 'Add Membership Plan',
                      style: AppTheme.headlineLg,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameController,
                  style: AppTheme.bodyMd,
                  decoration: const InputDecoration(
                    labelText: 'Plan Name *',
                    hintText: 'e.g. 1 Month, 3 Months, Quarterly',
                    prefixIcon: Icon(Icons.event_note),
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Plan name is required';
                    }
                    final existingPlans = ctx.read<AppDataProvider>().allJoinedPlans;
                    final duplicate = existingPlans.any((jp) {
                      if (isEdit && jp.plan.planId == plan.planId) return false;
                      return jp.plan.planName.trim().toLowerCase() == val.trim().toLowerCase();
                    });
                    if (duplicate) {
                      return 'A plan with this name already exists';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: durationController,
                        keyboardType: TextInputType.number,
                        style: AppTheme.bodyMd,
                        decoration: const InputDecoration(
                          labelText: 'Duration (Months) *',
                          prefixIcon: Icon(Icons.access_time),
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Required';
                          }
                          final months = int.tryParse(val);
                          if (months == null || months <= 0) {
                            return 'Enter > 0';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        style: AppTheme.bodyMd,
                        decoration: const InputDecoration(
                          labelText: 'Price (₹) *',
                          prefixIcon: Icon(Icons.currency_rupee),
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Required';
                          }
                          final p = double.tryParse(val);
                          if (p == null || p < 0) {
                            return 'Enter >= 0';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final newPlan = Plan(
                        planId: plan?.planId ?? '',
                        planName: nameController.text.trim(),
                        durationMonths: int.parse(durationController.text.trim()),
                        price: double.parse(priceController.text.trim()),
                      );

                      final provider = ctx.read<AppDataProvider>();
                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(ctx);

                      await provider.savePlan(newPlan);

                      if (ctx.mounted) {
                        navigator.pop();
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(isEdit ? 'Plan updated successfully!' : 'New Plan created successfully!'),
                            backgroundColor: AppTheme.primaryContainer,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.save),
                    label: Text(isEdit ? 'Save Plan Changes' : 'Create Plan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: AppTheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeletePlan(BuildContext context, JoinedPlan jp) async {
    if (jp.isInUse) {
      // Guarded Deletion Blocked Alert
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppTheme.tertiary),
              const SizedBox(width: 8),
              const Text('Cannot Delete Plan'),
            ],
          ),
          content: Text(
            '${jp.activeMemberCount} member(s) are currently assigned to "${jp.plan.planName}".\n\n'
            'Deleting this plan would break membership and renewal records. Please reassign those members before deleting this plan.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: AppTheme.onPrimary,
              ),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Normal Confirmation Alert
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Plan?'),
        content: Text('Are you sure you want to delete "${jp.plan.planName}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: AppTheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final messenger = ScaffoldMessenger.of(context);
      final provider = context.read<AppDataProvider>();
      final deleted = await provider.deletePlan(jp.plan.planId);

      if (deleted && context.mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Plan deleted successfully.'),
            backgroundColor: AppTheme.primaryContainer,
          ),
        );
      }
    }
  }

  Widget _buildPlanCard(BuildContext context, JoinedPlan jp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: InkWell(
          onTap: () => _showAddEditPlanModal(context, plan: jp.plan),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.stackMd),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryContainer.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.event_note, color: AppTheme.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            jp.plan.planName,
                            style: AppTheme.headlineMd.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '₹${jp.plan.price.toStringAsFixed(0)}',
                            style: AppTheme.displayStat.copyWith(
                              fontSize: 20,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${jp.plan.durationMonths} ${jp.plan.durationMonths == 1 ? 'Month' : 'Months'}',
                              style: AppTheme.labelSm.copyWith(
                                color: AppTheme.onSurfaceVariant,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: jp.isInUse
                                  ? AppTheme.primaryContainer.withValues(alpha: 0.2)
                                  : AppTheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${jp.activeMemberCount} Members',
                              style: AppTheme.labelSm.copyWith(
                                color: jp.isInUse ? AppTheme.primary : AppTheme.onSurfaceVariant,
                                letterSpacing: 0,
                                fontWeight: jp.isInUse ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: AppTheme.onSurfaceVariant, size: 20),
                  onPressed: () => _showAddEditPlanModal(context, plan: jp.plan),
                  tooltip: 'Edit Plan',
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: jp.isInUse ? AppTheme.outline : AppTheme.error,
                    size: 20,
                  ),
                  onPressed: () => _confirmDeletePlan(context, jp),
                  tooltip: 'Delete Plan',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppDataProvider>(
      builder: (context, provider, _) {
        final plansList = provider.allJoinedPlans;

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: Text(
              'Membership Plans',
              style: AppTheme.headlineMd.copyWith(color: AppTheme.onSurface),
            ),
            backgroundColor: AppTheme.surface,
          ),
          body: provider.isPlansLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
              : plansList.isEmpty
                  ? EmptyState(
                      title: 'No plans created yet',
                      subtitle: 'Tap the + button below to create your first membership plan.',
                      icon: Icons.event_note_outlined,
                      actionLabel: 'Create First Plan',
                      onAction: () => _showAddEditPlanModal(context),
                    )
                  : RefreshIndicator(
                      onRefresh: () => provider.loadPlans(),
                      color: AppTheme.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: plansList.length,
                        itemBuilder: (context, index) {
                          return _buildPlanCard(context, plansList[index]);
                        },
                      ),
                    ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddEditPlanModal(context),
            backgroundColor: AppTheme.primary,
            foregroundColor: AppTheme.onPrimary,
            icon: const Icon(Icons.add),
            label: Text(
              'Add Plan',
              style: AppTheme.labelSm.copyWith(color: AppTheme.onPrimary),
            ),
          ),
        );
      },
    );
  }
}
