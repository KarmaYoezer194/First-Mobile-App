import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../../providers/theme_provider.dart';

/// TEMPORARY debug page (route `/_gallery`, debug builds only) showing
/// every shared widget. Removed in the final consistency pass.
class WidgetGalleryPage extends ConsumerStatefulWidget {
  const WidgetGalleryPage({super.key});

  @override
  ConsumerState<WidgetGalleryPage> createState() => _WidgetGalleryPageState();
}

class _WidgetGalleryPageState extends ConsumerState<WidgetGalleryPage> {
  bool _switch = true;
  int _qty = 2;
  int _sort = 0;
  int _chip = 0;
  int _nav = 0;
  bool _fav = false;

  void _toast(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    Widget section(String title, Widget child) => Padding(
          padding: const EdgeInsets.only(bottom: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionLabel(title),
              const SizedBox(height: 10),
              child,
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Widget gallery'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GoldSwitch(
              value: isDark,
              semanticLabel: 'Dark mode',
              onChanged: (v) =>
                  ref.read(themeModeNotifierProvider.notifier).toggle(v),
            ),
          ),
        ],
      ),
      bottomNavigationBar: GoBuyBottomNav(
        currentIndex: _nav,
        onTap: (i) => setState(() => _nav = i),
        items: [
          const GoBuyNavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: 'Home'),
          const GoBuyNavItem(
              icon: Icons.search_outlined,
              activeIcon: Icons.search_rounded,
              label: 'Search'),
          GoBuyNavItem(
              icon: Icons.shopping_bag_outlined,
              activeIcon: Icons.shopping_bag_rounded,
              label: 'Cart',
              badgeCount: _qty),
          const GoBuyNavItem(
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: 'Profile'),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppConstants.pagePadding, 8,
            AppConstants.pagePadding, AppConstants.listBottomInset),
        children: [
          section(
            'Logo',
            const Wrap(spacing: 24, runSpacing: 12, children: [
              GoBuyLogo(),
              GoBuyLogo(size: 48),
            ]),
          ),
          section(
            'Buttons',
            Column(children: [
              PrimaryButton(
                  label: 'Sign In', onPressed: () => _toast('Primary')),
              const SizedBox(height: 10),
              const PrimaryButton(
                  label: 'Loading', onPressed: null, loading: true),
              const SizedBox(height: 10),
              SecondaryButton(
                  label: 'Add to Cart',
                  icon: Icons.shopping_bag_outlined,
                  onPressed: () => _toast('Secondary')),
            ]),
          ),
          section(
            'Text fields',
            Column(children: [
              const AppTextField(
                  label: 'Email',
                  hint: 'you@example.com',
                  icon: Icons.mail_outline_rounded),
              const SizedBox(height: 14),
              const AppTextField(
                  label: 'Password',
                  hint: 'Your password',
                  icon: Icons.lock_outline_rounded,
                  obscureText: true),
              const SizedBox(height: 14),
              AppTextField(
                hint: 'What are you looking for?',
                icon: Icons.search_rounded,
                trailing: FieldIconButton(
                  icon: Icons.photo_camera_outlined,
                  tooltip: 'Search by photo',
                  onPressed: () => _toast('Camera'),
                ),
              ),
              const SizedBox(height: 14),
              Form(
                autovalidateMode: AutovalidateMode.always,
                child: AppTextField(
                  label: 'With error',
                  hint: 'name@',
                  icon: Icons.mail_outline_rounded,
                  validator: (_) => 'Enter a valid email address',
                ),
              ),
            ]),
          ),
          section(
            'Circle icon buttons',
            Row(children: [
              CircleIconButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Back',
                  onPressed: () {}),
              const SizedBox(width: 8),
              CircleIconButton(
                  icon: Icons.notifications_none_rounded,
                  tooltip: 'Alerts',
                  showDot: true,
                  onPressed: () {}),
              const SizedBox(width: 8),
              CircleIconButton(
                  icon: Icons.shopping_bag_outlined,
                  tooltip: 'Cart',
                  badgeCount: _qty,
                  onPressed: () {}),
              const SizedBox(width: 8),
              CircleIconButton(
                  icon: Icons.settings_outlined,
                  tooltip: 'Settings',
                  onPressed: () {}),
            ]),
          ),
          section(
            'Section header',
            SectionHeader(
                title: 'Recommended', actionLabel: 'See more', onAction: () {}),
          ),
          section(
            'Category circles',
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CategoryCircle(
                    icon: Icons.devices_other_rounded,
                    label: 'Electronics',
                    onTap: () {}),
                CategoryCircle(
                    icon: Icons.man_rounded,
                    label: "Men's Fashion",
                    onTap: () {}),
                CategoryCircle(
                    icon: Icons.woman_rounded,
                    label: "Women's Fashion",
                    onTap: () {}),
                CategoryCircle(
                    icon: Icons.diamond_outlined,
                    label: 'Jewelry',
                    onTap: () {}),
              ],
            ),
          ),
          section(
            'Chips',
            Wrap(spacing: 8, children: [
              for (final (i, label)
                  in ['All', 'Electronics', 'Jewelry'].indexed)
                AppChip(
                  label: label,
                  selected: _chip == i,
                  icon: i == 0 ? Icons.apps_rounded : null,
                  onTap: () => setState(() => _chip = i),
                ),
              const AppChip(
                  label: 'XL',
                  selected: false,
                  onTap: null,
                  enabled: false,
                  strikethrough: true),
            ]),
          ),
          section(
            'Sort tabs',
            SortTabs(
              selectedIndex: _sort,
              onChanged: (i) => setState(() => _sort = i),
              items: const [
                SortTabItem('Popular'),
                SortTabItem('Latest'),
                SortTabItem('Best Sellers'),
                SortTabItem('Price',
                    trailingIcon: Icons.keyboard_arrow_down_rounded),
              ],
            ),
          ),
          section(
            'Product cards',
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: GoBuyProductCard(
                    imageUrl:
                        'https://fakestoreapi.com/img/81fPKd-2AYL._AC_SL1500_.jpg',
                    name: 'Fjallraven Backpack',
                    priceText: '\$109.95',
                    tag: 'New',
                    rating: 3.9,
                    ratingCount: 120,
                    isFavorite: _fav,
                    onToggleFavorite: () => setState(() => _fav = !_fav),
                    onTap: () => _toast('Open product'),
                    onAddToCart: () => _toast('Add to cart'),
                    onBuyNow: () => _toast('Buy now'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GoBuyProductCard(
                    imageUrl: '',
                    name: 'No rating, no image',
                    priceText: '\$22.30',
                    tag: "men's clothing",
                    onTap: () {},
                    onAddToCart: () {},
                    onBuyNow: () {},
                  ),
                ),
              ],
            ),
          ),
          section(
            'List row card',
            ListRowCard(children: [
              ListRow(
                icon: Icons.dark_mode_outlined,
                title: 'Dark mode',
                subtitle: 'Enabled',
                trailing: GoldSwitch(
                    value: _switch,
                    semanticLabel: 'Example switch',
                    onChanged: (v) => setState(() => _switch = v)),
              ),
              ListRow(
                  icon: Icons.language_rounded,
                  title: 'Language',
                  subtitle: 'English',
                  onTap: () {}),
              ListRow(
                  icon: Icons.local_shipping_outlined,
                  title: 'Order shipped',
                  darkWell: true,
                  onTap: () {}),
              ListRow(
                  icon: Icons.logout_rounded,
                  title: 'Log out',
                  destructive: true,
                  onTap: () {}),
            ]),
          ),
          section(
            'Quantity stepper',
            QuantityStepper(
                value: _qty,
                max: 9,
                onChanged: (v) => setState(() => _qty = v)),
          ),
          section(
            'Summary card',
            SummaryCard(
              lines: [
                const SummaryLine('Subtotal', '\$132.25'),
                const SummaryLine('Voucher (SAVE5)', '-\$5.00',
                    highlight: true),
                SummaryLine('Shipping', 'Free', valueColor: palette.success),
                const SummaryLine('Tax (8%)', '\$10.18'),
              ],
              totalValue: '\$137.43',
            ),
          ),
          section(
            'Stat tiles',
            const Row(children: [
              Expanded(
                  child: StatTile(
                      icon: Icons.receipt_long_outlined,
                      value: '3',
                      label: 'Orders')),
              SizedBox(width: 10),
              Expanded(
                  child: StatTile(
                      icon: Icons.star_outline_rounded,
                      value: '4',
                      label: 'Reviews')),
              SizedBox(width: 10),
              Expanded(
                  child: StatTile(
                      icon: Icons.toll_outlined,
                      value: '120',
                      label: 'Points')),
            ]),
          ),
          section(
            'Skeleton + entrance animation',
            Row(children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                    child: const SkeletonBlock(height: 80).entrance(index: i)),
              ],
            ]),
          ),
          section(
            'Empty state',
            const SizedBox(
              height: 320,
              child: PlaceholderState(
                icon: Icons.shopping_bag_outlined,
                title: 'Your cart is empty',
                message: 'Browse products and add something you love.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
