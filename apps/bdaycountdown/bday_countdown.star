"""
Applet: Bday Countdown
Summary: Countdown to multiple birthdays
Description: Add multiple birthdays and countdown to the next one!
Author: Jared Brockmyre
"""

load("humanize.star", "humanize")
load("i18n.star", "tr")
load("images/cake_frame1.png", CAKE_FRAME1 = "file")
load("images/cake_frame1@2x.png", CAKE_FRAME1_2X = "file")
load("images/cake_frame2.png", CAKE_FRAME2 = "file")
load("images/cake_frame2@2x.png", CAKE_FRAME2_2X = "file")
load("math.star", "math")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

def main(config):
    timezone = time.tz()
    now = time.now().in_location(timezone)
    nameColor = config.get("nameColor", "#0000ff")

    entries = []
    for i in range(1, 9):
        name = config.str("name{}".format(i))
        if name:
            month = int(config.get("birthMonth{}".format(i), "1"), 10)
            day = int(config.get("birthDay{}".format(i), "1"), 10)
            entries.append((name, month, day))

    if not entries:
        oldName = config.str("name")
        if oldName:
            name = oldName
            month = int(config.get("birthMonth", "1"), 10)
            day = int(config.get("birthDay", "1"), 10)
            entries.append((name, month, day))

    if not entries:
        name = tr("Someone")
        month = 1
        day = 1
        entries.append((name, month, day))

    bdays = []
    for name, month, day in entries:
        bday = time.time(year = now.year, month = month, day = day, location = timezone)
        diff = bday - now
        days = math.ceil(diff.hours / 24)

        if days < 0:
            bday = time.time(year = now.year + 1, month = month, day = day, location = timezone)
            diff = bday - now
            days = math.ceil(diff.hours / 24)

        bdays.append((days, name))

    nextDays = 367
    nextName = ""
    secondDays = 367
    secondName = ""
    for days, name in bdays:
        if days < nextDays:
            secondDays = nextDays
            secondName = nextName
            nextDays = days
            nextName = name
        elif days < secondDays:
            secondDays = days
            secondName = name

    scale = 2 if canvas.is2x() else 1
    if scale == 2:
        textFont = "terminus-14-light"
    else:
        textFont = "tom-thumb"

    secondBdayThreshold = int(config.get("secondBdayThreshold", "10"), 10)
    showSecond = secondBdayThreshold > 0 and secondName != "" and secondDays > 0 and nextDays <= secondBdayThreshold

    if nextDays == 0:
        if secondDays == 0:
            row1Text = "Happy"
            row2Text = "Birthday!"
            row3Text = nextName + " & " + secondName
            row4Text = ""
        else:
            row1Text = tr("Happy")
            row2Text = tr("Birthday")
            row3Text = nextName + "!" if nextName else ""
            row4Text = ""
    else:
        row1Text = humanize.plural(nextDays, tr("day"), tr("days"))
        row2Text = tr("until")
        row3Text = nextName + tr("'s") if nextName else tr("Your")
        row4Text = tr("birthday")

    textRows = [
        render.Text(content = row1Text, font = textFont),
        render.Text(content = row2Text, font = textFont),
        render.Text(content = row3Text, font = textFont, color = nameColor),
        render.Text(content = row4Text, font = textFont),
    ]

    cake1 = (CAKE_FRAME1_2X if scale == 2 else CAKE_FRAME1).readall()
    cake2 = (CAKE_FRAME2_2X if scale == 2 else CAKE_FRAME2).readall()

    def frame(src, rows):
        return render.Row(
            children = [
                render.Image(src = src, width = 24 * scale, height = 24 * scale),
                render.Box(
                    width = canvas.width() - 24 * scale,
                    height = canvas.height(),
                    child = render.Column(
                        cross_align = "center",
                        main_align = "center",
                        children = rows,
                    ),
                ),
            ],
        )

    pairs = 3

    displayChildren = []
    for _ in range(pairs):
        displayChildren.append(frame(cake1, textRows))
        displayChildren.append(frame(cake2, textRows))

    if showSecond:
        sRow1Text = humanize.plural(secondDays, tr("day"), tr("days"))
        sRow2Text = tr("until")
        sRow3Text = secondName + tr("'s")
        sRow4Text = tr("birthday")

        sTextRows = [
            render.Text(content = sRow1Text, font = textFont),
            render.Text(content = sRow2Text, font = textFont),
            render.Text(content = sRow3Text, font = textFont, color = nameColor),
            render.Text(content = sRow4Text, font = textFont),
        ]

        for _ in range(pairs):
            displayChildren.append(frame(cake1, sTextRows))
            displayChildren.append(frame(cake2, sTextRows))

    return render.Root(
        delay = 800,
        child = render.Animation(children = displayChildren),
    )

def get_schema():
    dayOptions = [schema.Option(display = str(i), value = str(i)) for i in range(1, 32)]
    monthOptions = [schema.Option(display = str(i), value = str(i)) for i in range(1, 13)]

    fields = []
    for i in range(1, 9):
        fields.append(schema.Text(
            id = "name{}".format(i),
            name = "Name {}".format(i),
            desc = "Birthday person's name (max 9 characters)" if i == 1 else "Birthday person {}'s name.".format(i),
            icon = "gear",
            default = "",
        ))
        fields.append(schema.Dropdown(
            id = "birthMonth{}".format(i),
            name = "Birth month {}".format(i),
            desc = "Birth month for person {}.".format(i),
            icon = "gear",
            default = monthOptions[0].value,
            options = monthOptions,
        ))
        fields.append(schema.Dropdown(
            id = "birthDay{}".format(i),
            name = "Birth day {}".format(i),
            desc = "Birth day for person {}.".format(i),
            icon = "gear",
            default = dayOptions[0].value,
            options = dayOptions,
        ))

    fields.append(schema.Dropdown(
        id = "secondBdayThreshold",
        name = "Second Birthday Alert",
        desc = "When 'Happy Birthday' is shown, also show the next birthday within this many days.",
        icon = "gear",
        default = "10",
        options = [
            schema.Option(display = "Off", value = "0"),
            schema.Option(display = "3 days", value = "3"),
            schema.Option(display = "5 days", value = "5"),
            schema.Option(display = "7 days", value = "7"),
            schema.Option(display = "10 days", value = "10"),
            schema.Option(display = "14 days", value = "14"),
            schema.Option(display = "21 days", value = "21"),
            schema.Option(display = "30 days", value = "30"),
            schema.Option(display = "45 days", value = "45"),
            schema.Option(display = "60 days", value = "60"),
        ],
    ))

    fields.append(schema.Color(
        id = "nameColor",
        name = "Name Color",
        desc = "Color of the name.",
        icon = "brush",
        default = "#0000FF",
    ))

    return schema.Schema(
        version = "1",
        fields = fields,
    )
