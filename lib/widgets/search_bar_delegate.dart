import 'package:flutter/material.dart';

class SearchBarDelegate extends SearchDelegate<String> {
  final Future<List<dynamic>> Function(String) onSearch;
  final List<String> recentSearches;

  SearchBarDelegate({
    required this.onSearch,
    required this.recentSearches,
  });

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: onSearch(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No results found'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final result = snapshot.data![index];
            return ListTile(
              title: Text(result.toString()),
              onTap: () => close(context, result.toString()),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = query.isEmpty
        ? recentSearches
        : recentSearches
            .where(
                (search) => search.toLowerCase().contains(query.toLowerCase()))
            .toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = suggestions[index];
        return ListTile(
          leading: const Icon(Icons.history),
          title: Text(suggestion),
          onTap: () {
            query = suggestion;
            showResults(context);
          },
        );
      },
    );
  }
}
