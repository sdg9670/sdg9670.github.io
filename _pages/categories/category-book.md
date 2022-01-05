---
title: "Post about Book"
layout: archive
permalink: /categories/book
author_profile: true
---

{% assign posts = site.categories.book | sort:"date" | reverse %}

{% for post in posts %}
{% include archive-single.html type=page.entries_layout %}
{% endfor %}
