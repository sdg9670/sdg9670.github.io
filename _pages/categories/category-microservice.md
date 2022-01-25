---
title: "Post about Microservice"
layout: archive
permalink: /categories/microservice
author_profile: true
---

{% assign posts = site.categories.microservice | sort:"date" | reverse %}

{% for post in posts %}
{% include archive-single.html type=page.entries_layout %}
{% endfor %}
