import 'package:flutter/material.dart';

class MealScreen extends StatelessWidget {
  const MealScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meals', style: TextStyle(color: Colors.deepOrange)),
        backgroundColor: Colors.white,
        toolbarHeight: 70,
      ),
      body: Center(
        child: Column(
          children: const [
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Choose Your Kitchen',
                style: TextStyle(fontSize: 24),
              ),
            ),
            SizedBox(height: 8),
            MealCard(
              title: 'Red Plate',
              subtitle:
                  'Premium customizable meals with rice, viands, and sides',
              badgeText: 'Campus Canteen',
              badgeColor: Color.fromARGB(255, 255, 255, 35),
              cornerTagText: 'Premium Kitchen',
              cornerTagColor: Colors.red,
              price: '₱120',
              priceLabel: 'starting at',
              image: 'assets/images/Meals.png',
            ),
            SizedBox(height: 20),
            MealCard(
              title: 'Silver Plate',
              subtitle: 'Classic set meals with rice and main dish combos.',
              badgeText: 'Best Value',
              badgeColor: Colors.white,
              cornerTagText: 'Premium Kitchen',
              cornerTagColor: Colors.blueGrey,
              price: '₱120',
              priceLabel: 'starting at',
              image: 'assets/images/Meals.png',
            ),
          ],
        ),
      ),
    );
  }
}

class MealCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badgeText;
  final Color badgeColor;
  final String cornerTagText;
  final Color cornerTagColor;
  final String price;
  final String priceLabel;
  final String image;

  const MealCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.badgeColor,
    required this.cornerTagText,
    required this.cornerTagColor,
    required this.price,
    required this.priceLabel,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: navigate to detail or menu list for this kitchen
      },
      child: Container(
        width: 330,
        height: 180,
        margin: const EdgeInsets.symmetric(horizontal: 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(image: AssetImage(image), fit: BoxFit.cover),
        ),
        child: Stack(
          children: [
            Positioned(
              bottom: 60,
              left: 20,
              child: SizedBox(
                width: 240,
                height: 80,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 30,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 135,
              left: 20,
              child: Container(
                width: 100,
                height: 25,
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(15),
                ),
                alignment: Alignment.center,
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeColor.computeLuminance() > 0.5
                        ? Colors.black
                        : Colors.white,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              left: 220,
              child: Container(
                width: 100,
                height: 25,
                decoration: BoxDecoration(
                  color: cornerTagColor,
                  borderRadius: BorderRadius.circular(15),
                ),
                alignment: Alignment.center,
                child: Text(
                  cornerTagText,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
            Positioned(
              top: 100,
              left: 220,
              child: SizedBox(
                width: 240,
                height: 80,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      price,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 30,
                      ),
                    ),
                    Text(
                      priceLabel,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
