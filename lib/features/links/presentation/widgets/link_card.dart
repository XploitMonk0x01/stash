import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/utils/url_validator.dart';
import '../../data/link_repository.dart';
import '../../domain/link_model.dart';

class LinkCard extends ConsumerWidget {
  final LinkModel link;
  final VoidCallback? onEdit;

  const LinkCard({super.key, required this.link, this.onEdit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final catColor = AppColors.getCategoryColor(link.category);
    final safeFaviconUrl = link.faviconUrl.isNotEmpty && link.faviconUrl.startsWith('http')
        ? link.faviconUrl
        : UrlValidator.getFaviconUrl(link.url);

    return Dismissible(
      key: ValueKey(link.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: AppColors.error, size: 28),
      ),
      confirmDismiss: (_) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Archive link?'),
            content: const Text(
              'This removes the link from your list. You can undo from the next snackbar.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Archive'),
              ),
            ],
          ),
        );
        return confirmed ?? false;
      },
      onDismissed: (_) {
        HapticFeedback.heavyImpact();
        final repo = ref.read(linkRepositoryProvider);
        repo.archiveLink(link.id);
        SnackbarUtils.showUndo(
          context,
          'Link archived',
          () => repo.unarchiveLink(link.id),
        );
      },
      child: GestureDetector(
        onTap: () => _openUrl(context),
        onLongPress: () => _toggleFavourite(context, ref),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : AppColors.accent).withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                color: (isDark ? AppColors.darkSurface : AppColors.lightSurface).withOpacity(0.85),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Favicon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceLight
                            : AppColors.lightSurfaceLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: safeFaviconUrl,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          placeholder: (ctx, url) => _buildFaviconPlaceholder(isDark),
                          errorWidget: (ctx, url, err) =>
                              _buildFaviconPlaceholder(isDark),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title + favourite
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  link.label.isNotEmpty ? link.label : link.pageTitle,
                                  style: theme.textTheme.titleSmall,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                onPressed: () => _toggleFavourite(context, ref),
                                tooltip: link.isFavourite
                                    ? 'Remove from favourites'
                                    : 'Add to favourites',
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: Icon(
                                  link.isFavourite
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  size: 20,
                                  color: link.isFavourite
                                      ? AppColors.favouriteStar
                                      : (isDark
                                          ? AppColors.darkTextTertiary
                                          : AppColors.lightTextTertiary),
                                ).animate(key: ValueKey(link.isFavourite))
                                 .scaleXY(begin: 0.8, end: 1.0, duration: 400.ms, curve: Curves.elasticOut),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // URL
                          Text(
                            UrlValidator.extractDomain(link.url) ?? link.url,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.darkTextTertiary
                                  : AppColors.lightTextTertiary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),

                          // Category badge + time + edit
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? catColor.background
                                      : catColor.lightBackground,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isDark
                                        ? catColor.border
                                        : catColor.lightBorder,
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  link.category,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        isDark ? catColor.text : catColor.lightText,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                DateFormatter.relativeTime(link.createdAt),
                                style: theme.textTheme.labelSmall,
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => _copyUrl(context),
                                child: Icon(
                                  Icons.copy_rounded,
                                  size: 16,
                                  color: isDark
                                      ? AppColors.darkTextTertiary
                                      : AppColors.lightTextTertiary,
                                ),
                              ),
                              if (onEdit != null) ...[
                                const SizedBox(width: 16),
                                GestureDetector(
                                  onTap: onEdit,
                                  child: Icon(
                                    Icons.edit_outlined,
                                    size: 16,
                                    color: isDark
                                        ? AppColors.darkTextTertiary
                                        : AppColors.lightTextTertiary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFaviconPlaceholder(bool isDark) {
    return Container(
      width: 40,
      height: 40,
      color: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceLight,
      child: Icon(
        Icons.language_rounded,
        size: 20,
        color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
      ),
    );
  }

  Future<void> _openUrl(BuildContext context) async {
    final uri = Uri.tryParse(link.url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        SnackbarUtils.showError(context, 'Could not open URL');
      }
    }
  }

  void _toggleFavourite(BuildContext context, WidgetRef ref) {
    HapticFeedback.mediumImpact();
    ref
        .read(linkRepositoryProvider)
        .toggleFavourite(link.id, !link.isFavourite);
    SnackbarUtils.showInfo(
      context,
      link.isFavourite ? 'Removed from favourites' : 'Added to favourites',
    );
  }

  void _copyUrl(BuildContext context) {
    HapticFeedback.selectionClick();
    Clipboard.setData(ClipboardData(text: link.url));
    SnackbarUtils.showInfo(context, 'URL copied to clipboard');
  }
}
