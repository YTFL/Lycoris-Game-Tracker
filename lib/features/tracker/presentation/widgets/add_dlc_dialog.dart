import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/utils/text_field_helper.dart';
import '../../../search/data/igdb_service.dart';
import '../../../sync/presentation/controllers/settings_notifier.dart';
import '../../domain/models/additional_expense.dart';
import '../../domain/models/game_entry.dart';
import '../controllers/library_notifier.dart';

class AddDlcDialog extends ConsumerStatefulWidget {
  final GameEntry game;

  const AddDlcDialog({
    super.key,
    required this.game,
  });

  static Future<void> show(BuildContext context, GameEntry game) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AddDlcDialog(game: game),
    );
  }

  @override
  ConsumerState<AddDlcDialog> createState() => _AddDlcDialogState();
}

class _AddDlcDialogState extends ConsumerState<AddDlcDialog> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _searchFilterController = TextEditingController();

  bool _isLoadingDlcs = false;
  List<IGDBDlcResult> _allDlcs = [];
  List<IGDBDlcResult> _filteredDlcs = [];
  IGDBDlcResult? _selectedDlc;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDlcs();
    _searchFilterController.addListener(_onSearchFilterChanged);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _searchFilterController.dispose();
    super.dispose();
  }

  void _onSearchFilterChanged() {
    final query = _searchFilterController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredDlcs = List.from(_allDlcs);
      } else {
        _filteredDlcs = _allDlcs
            .where((dlc) => dlc.title.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  Future<void> _fetchDlcs() async {
    if (widget.game.igdbId <= 0) return;

    setState(() {
      _isLoadingDlcs = true;
      _errorMessage = null;
    });

    try {
      final igdbService = ref.read(igdbServiceProvider);
      final dlcs = await igdbService.fetchGameDlcs(widget.game.igdbId);
      if (mounted) {
        setState(() {
          _allDlcs = dlcs;
          _filteredDlcs = dlcs;
          _isLoadingDlcs = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingDlcs = false;
          _errorMessage = 'Could not load official DLCs';
        });
      }
    }
  }

  void _selectDlc(IGDBDlcResult dlc) {
    setState(() {
      _selectedDlc = dlc;
      _titleController.text = dlc.title;
    });
  }

  void _submit() {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter or select a DLC title')),
      );
      return;
    }

    final expense = AdditionalExpense(
      id: const Uuid().v4(),
      title: title,
      amount: amount,
      date: DateTime.now(),
    );

    ref.read(libraryNotifierProvider.notifier).addExpense(widget.game.id, expense);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isCustomGame = widget.game.igdbId <= 0;

    return Dialog(
      backgroundColor: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant.withAlpha(60)),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.add_shopping_cart_rounded, size: 20, color: colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add DLC & Expansions',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          widget.game.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // IGDB Suggestions Section
              if (!isCustomGame) ...[
                Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 14, color: colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      'IGDB Official DLCs & Expansions',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                    ),
                    const Spacer(),
                    if (_allDlcs.isNotEmpty)
                      Text(
                        '${_allDlcs.length} found',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                if (_isLoadingDlcs)
                  Container(
                    height: 110,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Searching IGDB for DLCs...',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (_allDlcs.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _errorMessage ?? 'No standalone DLCs listed in IGDB. Enter details manually below.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else ...[
                  // Search filter input for large DLC lists
                  if (_allDlcs.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SizedBox(
                        height: 36,
                        child: TextField(
                          controller: _searchFilterController,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Filter DLCs...',
                            prefixIcon: const Icon(Icons.search, size: 16),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: colorScheme.outlineVariant.withAlpha(50)),
                            ),
                            filled: true,
                            fillColor: colorScheme.surfaceContainer,
                          ),
                        ),
                      ),
                    ),

                  // DLC cards horizontal scroll
                  SizedBox(
                    height: 110,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filteredDlcs.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final dlc = _filteredDlcs[index];
                        final isSelected = _selectedDlc?.id == dlc.id;

                        return InkWell(
                          onTap: () => _selectDlc(dlc),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 160,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colorScheme.primaryContainer.withAlpha(80)
                                  : colorScheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.outlineVariant.withAlpha(50),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (dlc.coverBigUrl != null)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: CachedNetworkImage(
                                          imageUrl: dlc.coverBigUrl!,
                                          width: 24,
                                          height: 32,
                                          fit: BoxFit.cover,
                                          errorWidget: (context, url, error) =>
                                              const Icon(Icons.extension_rounded, size: 20),
                                        ),
                                      )
                                    else
                                      Container(
                                        width: 24,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: colorScheme.surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Icon(Icons.extension_rounded,
                                            size: 16, color: colorScheme.primary),
                                      ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: colorScheme.primary.withAlpha(25),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              dlc.categoryLabel,
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                                color: colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                          if (dlc.releaseDate != null)
                                            Text(
                                              DateFormat.y().format(dlc.releaseDate!),
                                              style: theme.textTheme.labelSmall?.copyWith(
                                                color: colorScheme.onSurfaceVariant,
                                                fontSize: 10,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(Icons.check_circle_rounded,
                                          size: 16, color: colorScheme.primary),
                                  ],
                                ),
                                const Spacer(),
                                Text(
                                  dlc.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    color: colorScheme.onSurface,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 16),
              ],

              // Manual Input Fields
              Text(
                'Expense Details',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),

              TextField(
                controller: _titleController,
                onTap: () => TextFieldHelper.selectAll(_titleController),
                decoration: InputDecoration(
                  labelText: 'DLC / Expense Title',
                  hintText: 'e.g. Season Pass, Deluxe Pack, Expansion',
                  prefixIcon: const Icon(Icons.title_rounded, size: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _amountController,
                onTap: () => TextFieldHelper.selectAll(_amountController),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount Paid (${widget.game.currency})',
                  hintText: '0.00 for free / bundled',
                  prefixIcon: const Icon(Icons.attach_money_rounded, size: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Add Expense'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
