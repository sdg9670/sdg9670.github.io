---
title: "Post about Jenkins"
layout: archive
permalink: /categories/jenkins
author_profile: true
---

{% assign posts = site.categories.jenkins | sort:"date" %}

{% for post in posts %}
  {% include archive-single.html type=page.entries_layout %}
{% endfor %}
