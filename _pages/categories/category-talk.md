---
title: "Post about Talk"
layout: archive
permalink: /categories/talk
author_profile: true
---

{% assign posts = site.categories.talk | sort:"date" %}

{% for post in posts %}
  {% include archive-single.html type=page.entries_layout %}
{% endfor %}
