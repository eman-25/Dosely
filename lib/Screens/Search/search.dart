import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
	const SearchScreen({Key? key}) : super(key: key);

	@override
	State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
	final TextEditingController _controller = TextEditingController();
	bool _showRecent = false;
	String _query = '';
    static const c1 = Color(0xFF48466E);
  static const c2 = Color(0xFF3E84A8);
  static const c3 = Color(0xFF4ACED0);
  static const c4 = Color(0xFFACEDD9);
  static const c5 = Color(0xFFE0FBF4);
	final List<String> _recent = [
		'Vitamin B12',
		'Folic Acid',
		'Ibuprofen',
	];

	final List<Map<String, String>> _meds = [
		{
			'title': 'Vitamin B12',
			'desc':
					'Vitamin B12 is essential for healthy nerve function and creating red blood cells. It keeps your brain sharp and your energy levels high.',
			'image':
					'https://upload.wikimedia.org/wikipedia/commons/thumb/1/12/Vitamin_B12_supplement.jpg/240px-Vitamin_B12_supplement.jpg'
		},
		{
			'title': 'Folic Acid',
			'desc': 'Folic acid helps with cell growth and reproduction.',
			'image':
					'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0b/Folic_Acid_Bottle.jpg/240px-Folic_Acid_Bottle.jpg'
		},
		{
			'title': 'Ibuprofen',
			'desc': 'Common pain reliever and anti-inflammatory.',
			'image':
					'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c8/Ibuprofen_bottle.jpg/240px-Ibuprofen_bottle.jpg'
		},
	];

	List<Map<String, String>> get _filtered => _meds
			.where((m) => m['title']!.toLowerCase().contains(_query.toLowerCase()))
			.toList();

	void _onSearchChanged(String v) {
		setState(() {
			_query = v;
		});
	}

	void _useRecent(String text) {
		_controller.text = text;
		_onSearchChanged(text);
		setState(() => _showRecent = false);
	}

	@override
	Widget build(BuildContext context) {
		final theme = Theme.of(context);

		return Scaffold(
			resizeToAvoidBottomInset: false,
			body: Container(
				decoration: const BoxDecoration(
					gradient: LinearGradient(
						colors: [c1, c2, c3, c4, c5],
						begin: Alignment.topCenter,
						end: Alignment.bottomCenter,
					),
				),
				padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						Row(
							children: [
								Expanded(
									child: Container(
										padding: const EdgeInsets.symmetric(horizontal: 12),
										decoration: BoxDecoration(
											color: Colors.white.withOpacity(0.9),
											borderRadius: BorderRadius.circular(28),
											boxShadow: [
												BoxShadow(
													color: Colors.black.withOpacity(0.06),
													blurRadius: 6,
													offset: const Offset(0, 3),
												)
											],
										),
										child: Row(
											children: [
												Icon(Icons.search, color: theme.hintColor),
												const SizedBox(width: 8),
												Expanded(
													child: TextField(
														controller: _controller,
														onChanged: _onSearchChanged,
														decoration: InputDecoration(
															hintText: 'Search Medication',
															border: InputBorder.none,
														),
													),
												),
												GestureDetector(
													onTap: () {
														_controller.clear();
														setState(() => _query = '');
													},
													child: Icon(Icons.close, size: 18, color: theme.hintColor),
												),
												const SizedBox(width: 8),
											],
										),
									),
								),

								const SizedBox(width: 12),

								// three-line icon that toggles recent searches
								InkWell(
									onTap: () => setState(() => _showRecent = !_showRecent),
									borderRadius: BorderRadius.circular(12),
									child: Container(
										padding: const EdgeInsets.all(10),
										decoration: BoxDecoration(
											color: Colors.white.withOpacity(0.9),
											borderRadius: BorderRadius.circular(12),
											boxShadow: [
												BoxShadow(
													color: Colors.black.withOpacity(0.06),
													blurRadius: 6,
													offset: const Offset(0, 3),
												)
											],
										),
										child: Column(
											mainAxisSize: MainAxisSize.min,
											children: const [
												Icon(Icons.menu, size: 18),
											],
										),
									),
								)
							],
						),

						const SizedBox(height: 12),

						// recent searches panel (3-line icon toggles this)
						AnimatedCrossFade(
							firstChild: const SizedBox.shrink(),
							secondChild: _buildRecentPanel(theme),
							crossFadeState:
									_showRecent ? CrossFadeState.showSecond : CrossFadeState.showFirst,
							duration: const Duration(milliseconds: 220),
						),

						const SizedBox(height: 12),

						// results list
						Expanded(
							child: ListView.builder(
								itemCount: _filtered.length,
								padding: const EdgeInsets.only(bottom: 24),
								itemBuilder: (context, i) {
									final m = _filtered[i];
									return _buildMedicineCard(m['title']!, m['desc']!, m['image']!, theme);
								},
							),
						),
					],
				),
			),
		);
	}

	Widget _buildRecentPanel(ThemeData theme) {
		return Container(
			padding: const EdgeInsets.all(12),
			decoration: BoxDecoration(
				color: Colors.white.withOpacity(0.9),
				borderRadius: BorderRadius.circular(12),
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Row(
						mainAxisAlignment: MainAxisAlignment.spaceBetween,
						children: [
							Text('Recent searches', style: theme.textTheme.titleMedium),
							TextButton(
								onPressed: () => setState(() => _recent.clear()),
								child: const Text('Clear'),
							)
						],
					),
					const SizedBox(height: 8),
					Wrap(
						spacing: 8,
						runSpacing: 8,
						children: _recent.map((r) {
							return ActionChip(
								label: Text(r),
								onPressed: () => _useRecent(r),
							);
						}).toList(),
					)
				],
			),
		);
	}

	Widget _buildMedicineCard(String title, String desc, String image, ThemeData theme) {
		return Container(
			margin: const EdgeInsets.symmetric(vertical: 12),
			padding: const EdgeInsets.all(14),
			decoration: BoxDecoration(
				color: Colors.white,
				borderRadius: BorderRadius.circular(12),
				boxShadow: [
					BoxShadow(
						color: Colors.black.withOpacity(0.06),
						blurRadius: 8,
						offset: const Offset(0, 4),
					)
				],
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Row(
						children: [
							Container(
								width: 86,
								height: 86,
								padding: const EdgeInsets.all(6),
								decoration: BoxDecoration(
									border: Border.all(color: Colors.grey.shade200),
									borderRadius: BorderRadius.circular(6),
									color: Colors.white,
								),
								child: Image.network(image, fit: BoxFit.contain),
							),
							const SizedBox(width: 14),
							Expanded(
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
										const SizedBox(height: 6),
										Text(desc, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
										const SizedBox(height: 10),
										Align(
											alignment: Alignment.centerLeft,
											child: OutlinedButton(
												onPressed: () {},
												child: const Text('More info'),
											),
										)
									],
								),
							)
						],
					),
				],
			),
		);
	}
}

