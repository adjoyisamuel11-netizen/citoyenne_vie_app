import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/storage_service.dart';
import '../clients/client_liste_screen.dart';
import '../stats/stats_detail_screen.dart';

/// Écran d'accueil / Tableau de bord principal.
/// Consomme GET /api/stats/dashboard pour des données réelles.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiClient _apiClient = ApiClient();

  bool _isLoading = true;
  String? _errorMessage;
  String _prenomAgent = "";

  Map<String, dynamic> _portefeuille = {};
  Map<String, dynamic> _primes = {};
  Map<String, dynamic> _encaissements = {};

  @override
  void initState() {
    super.initState();
    _chargerNomAgent();
    _chargerDashboard();
  }

  Future<void> _chargerNomAgent() async {
    final token = await StorageService.getToken();
    if (token == null) return;
    final payload = _decodeToken(token);
    if (mounted) setState(() => _prenomAgent = payload['prenom']?.toString() ?? '');
  }

  Map<String, dynamic> _decodeToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return {};
      var normalized = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      switch (normalized.length % 4) {
        case 2:
          normalized += '==';
          break;
        case 3:
          normalized += '=';
          break;
      }
      return jsonDecode(utf8.decode(base64Url.decode(normalized)));
    } catch (_) {
      return {};
    }
  }

  Future<void> _chargerDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiClient.get('/stats/dashboard');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _portefeuille = Map<String, dynamic>.from(data['portefeuille'] ?? {});
            _primes = Map<String, dynamic>.from(data['primes'] ?? {});
            _encaissements = Map<String, dynamic>.from(data['encaissements'] ?? {});
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = "Erreur lors du chargement des statistiques (${response.statusCode}).";
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Impossible de contacter le serveur.";
          _isLoading = false;
        });
      }
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning),
            SizedBox(width: 8),
            Text("Déconnexion"),
          ],
        ),
        content: const Text("Voulez-vous vraiment vous déconnecter ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Annuler", style: TextStyle(color: AppColors.textGrey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRed, foregroundColor: AppColors.white),
            onPressed: () async {
              await StorageService.clearSession();
              if (ctx.mounted) Navigator.of(ctx).pop();
              // TODO: Navigator.pushAndRemoveUntil vers LoginScreen
            },
            child: const Text("Oui, me déconnecter"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 700;
    final String today = _formatDateFr(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: RefreshIndicator(
        onRefresh: _chargerDashboard,
        color: AppColors.primaryGreen,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(today)),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Container(
                    constraints: BoxConstraints(maxWidth: isDesktop ? 1000 : double.infinity),
                    child: _isLoading
                        ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
                    )
                        : _errorMessage != null
                        ? _buildErreur()
                        : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FadeSlideIn(
                          delay: const Duration(milliseconds: 0),
                          child: _buildStatsRapides(isDesktop),
                        ),
                        const SizedBox(height: 16),
                        _FadeSlideIn(
                          delay: const Duration(milliseconds: 120),
                          child: _buildBoutonVoirPlus(),
                        ),
                        const SizedBox(height: 28),
                        _FadeSlideIn(
                          delay: const Duration(milliseconds: 220),
                          child: _buildTitreSection("Actions rapides"),
                        ),
                        const SizedBox(height: 12),
                        _FadeSlideIn(
                          delay: const Duration(milliseconds: 300),
                          child: _buildQuickActions(isDesktop),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String today) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 28),
      decoration: const BoxDecoration(
        gradient: AppColors.softHeaderGradient,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _prenomAgent.isEmpty ? "Bonjour 👋" : "Bonjour, $_prenomAgent 👋",
                  style: const TextStyle(color: AppColors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(today, style: TextStyle(color: AppColors.white.withValues(alpha: 0.85), fontSize: 13)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.white),
            tooltip: "Déconnexion",
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildErreur() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 44),
            const SizedBox(height: 10),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            ElevatedButton(onPressed: _chargerDashboard, child: const Text("Réessayer")),
          ],
        ),
      ),
    );
  }

  Widget _buildTitreSection(String titre) {
    return Text(titre, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark));
  }

  Widget _buildStatsRapides(bool isDesktop) {
    final montantJour = double.tryParse((_encaissements['aujourd_hui'] ?? 0).toString()) ?? 0;
    final assuresActifs = int.tryParse((_portefeuille['actifs'] ?? 0).toString()) ?? 0;
    final primesEnCours = int.tryParse((_primes['en_cours'] ?? 0).toString()) ?? 0;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isDesktop ? 3 : 2,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: isDesktop ? 1.3 : 1.05,
      children: [
        _AnimatedStatCard(
          title: "Collecté aujourd'hui",
          value: montantJour,
          suffix: " FCFA",
          isMonetaire: true,
          icon: Icons.account_balance_wallet_rounded,
          color: AppColors.primaryGreen,
        ),
        _AnimatedStatCard(
          title: "Assurés actifs",
          value: assuresActifs.toDouble(),
          icon: Icons.people_alt_rounded,
          color: AppColors.info,
        ),
        _AnimatedStatCard(
          title: "Primes en cours",
          value: primesEnCours.toDouble(),
          icon: Icons.assignment_turned_in_rounded,
          color: AppColors.warning,
        ),
      ],
    );
  }

  Widget _buildBoutonVoirPlus() {
    return OutlinedButton.icon(
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const StatsDetailScreen()));
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryGreen,
        side: const BorderSide(color: AppColors.primaryGreen),
        minimumSize: const Size(double.infinity, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: const Icon(Icons.bar_chart_rounded),
      label: const Text("Voir toutes les statistiques"),
    );
  }

  Widget _buildQuickActions(bool isDesktop) {
    final actions = [
      _QuickAction(
        label: "Gestion des Assurés",
        icon: Icons.people_outline_rounded,
        color: AppColors.primaryGreen,
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientsListeScreen()));
        },
      ),
      _QuickAction(
        label: "Statistiques",
        icon: Icons.insights_rounded,
        color: AppColors.info,
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const StatsDetailScreen()));
        },
      ),
      _QuickAction(
        label: "Encaisser",
        icon: Icons.payments_rounded,
        color: AppColors.primaryRed,
        onTap: () {
          // TODO: nécessite de choisir un client/une prime d'abord
        },
      ),
      _QuickAction(
        label: "Rechercher",
        icon: Icons.search_rounded,
        color: AppColors.warning,
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientsListeScreen()));
        },
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isDesktop ? 4 : 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: actions,
    );
  }

  String _formatDateFr(DateTime date) {
    const jours = ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"];
    const mois = [
      "janvier", "février", "mars", "avril", "mai", "juin", "juillet",
      "août", "septembre", "octobre", "novembre", "décembre"
    ];
    return "${jours[date.weekday - 1]} ${date.day} ${mois[date.month - 1]} ${date.year}";
  }
}

/// Petit widget d'apparition en fondu + léger glissement, avec délai configurable.
class _FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _FadeSlideIn({required this.child, this.delay = Duration.zero});

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 0.08),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Carte stat avec compteur animé (0 -> valeur réelle) à l'apparition.
class _AnimatedStatCard extends StatelessWidget {
  final String title;
  final double value;
  final String suffix;
  final bool isMonetaire;
  final IconData icon;
  final Color color;

  const _AnimatedStatCard({
    required this.title,
    required this.value,
    this.suffix = "",
    this.isMonetaire = false,
    required this.icon,
    required this.color,
  });

  String _formatValeur(double v) {
    if (isMonetaire) {
      final str = v.toInt().toString();
      final buffer = StringBuffer();
      for (int i = 0; i < str.length; i++) {
        if (i != 0 && (str.length - i) % 3 == 0) buffer.write(' ');
        buffer.write(str[i]);
      }
      return "$buffer$suffix";
    }
    return "${v.toInt()}$suffix";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 14),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value),
            duration: const Duration(milliseconds: 1100),
            curve: Curves.easeOutCubic,
            builder: (context, animatedValue, child) {
              return Text(
                _formatValeur(animatedValue),
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppColors.textDark),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 12.5, color: AppColors.textGrey, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textDark),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}