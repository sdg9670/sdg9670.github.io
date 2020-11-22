---
title: "Post about GraphQL"
layout: archive
permalink: /categories/graphql
author_profile: true
---

{% assign posts = site.categories.graphql | sort:"date" %}

{% for post in posts %}
{% include archive-single.html type=page.entries_layout %}
{% endfor %}
