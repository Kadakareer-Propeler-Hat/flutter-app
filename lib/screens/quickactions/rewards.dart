import 'package:flutter/material.dart';

class RewardsPage extends StatelessWidget {
  const RewardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Back to Home",
          style: TextStyle(color: Colors.black),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [

            // ----------- CENTERED HEADER -----------
            const CircleAvatar(
              radius: 38,
              backgroundColor: Color(0xFFB388FF),
              child: Icon(Icons.card_giftcard, size: 38, color: Colors.white),
            ),
            const SizedBox(height: 14),

            const Text(
              "Rewards",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),

            const Text(
              "Make financial wellness fun and engaging",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.black54),
            ),

            const SizedBox(height: 28),

            // ------------ GRID ------------
            _infoGrid(),

            const SizedBox(height: 32),

            // ------------ DAILY CHALLENGES ------------
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Daily Challenges",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 14),

            _dailyChallenges(),

            const SizedBox(height: 28),

            // ------------ MILESTONES ------------
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Milestones",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 14),

            _milestonesContainer(),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------
  // INFO GRID BOXES
  // -------------------------------------------------------------------

  Widget _infoGrid() {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.3,
      ),
      children: [
        _statBox(
          color: Colors.red.shade700,
          icon: Icons.trending_up,
          label: "Level",
          value: "12",
        ),
        _statBox(
          color: Colors.orange.shade700,
          icon: Icons.add_reaction,
          label: "Points",
          value: "6,540",
        ),
        _statBox(
          color: Colors.orange.shade700,
          icon: Icons.local_fire_department,
          label: "Current Streak",
          value: "23 days",
        ),
        _statBox(
          color: Colors.orange.shade700,
          icon: Icons.emoji_events,
          label: "Rank",
          value: "#4",
        ),
      ],
    );
  }

  Widget _statBox({
    required Color color,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 30),
          const Spacer(),
          Text(label, style: const TextStyle(color: Colors.white)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------
  // DAILY CHALLENGES
  // -------------------------------------------------------------------

  Widget _dailyChallenges() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _challenge(
            title: "Make on-time payment",
            points: "+50 points",
            claimable: true,
            completed: true,
          ),
          _challenge(
            title: "Complete financial literacy quiz",
            points: "+100 points",
            claimable: true,
            completed: true,
          ),
          _challenge(
            title: "Set up auto-pay",
            points: "+75 points",
            progress: 0.35,
          ),
          _challenge(
            title: "Maintain 30-day streak",
            points: "+200 points",
            locked: true,
          ),
          _challenge(
            title: "Refer 3 friends",
            points: "+300 points",
            progress: 0.25,
          ),
        ],
      ),
    );
  }

  Widget _challenge({
    required String title,
    required String points,
    bool claimable = false,
    bool completed = false,
    bool locked = false,
    double progress = 0.0,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: completed ? Colors.green.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: completed ? Colors.green : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // TITLE + RIGHT-SIDE ICON/BUTTON
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),

              if (locked)
                const Icon(Icons.lock, color: Colors.grey)

              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  decoration: BoxDecoration(
                    color: completed ? Colors.green : Colors.green.shade400,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    "Claim",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          if (!locked && !completed)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation(Colors.blue),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  points,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),

          if (completed)
            Text(
              points,
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------
  // MILESTONES — now full container like Daily Challenges
  // -------------------------------------------------------------------

  Widget _milestonesContainer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _milestone("First Payment", "Oct 15, 2024", completed: true),
          _milestone("10 On-Time Payments", "Nov 20, 2024", completed: true),
          _milestone("6-Month Streak", "In Progress", completed: false),
          _milestone("Debt-Free Achievement", "Locked", locked: true),
        ],
      ),
    );
  }

  Widget _milestone(String title, String subtitle,
      {bool completed = false, bool locked = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: completed ? Colors.green.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: completed ? Colors.green : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: locked ? Colors.grey : Colors.black54,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          Icon(
            completed
                ? Icons.check_circle
                : locked
                ? Icons.lock
                : Icons.hourglass_empty,
            color: completed ? Colors.green : Colors.grey,
            size: 30,
          ),
        ],
      ),
    );
  }
}
