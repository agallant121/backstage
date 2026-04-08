# This file contains repeatable demo content for local development.

unless Rails.env.local? || ENV["ALLOW_DEMO_SEEDS"] == "true"
  abort("Demo seeds are disabled outside development and test. Set ALLOW_DEMO_SEEDS=true to run intentionally.")
end

PASSWORD = "password123!".freeze
EMAIL_DOMAIN = "backstage.test".freeze
SUMMARY_TEXT = "AI summaries can recap these group updates when OPENAI_API_KEY is configured.".freeze

GROUP_DEFINITIONS = [
  {
    name: "Sunday Family Loop",
    description: "Parents, siblings, cousins, and the steady stream of weekend family updates.",
    member_names: [
      ["Maggie", "Reynolds"],
      ["Evan", "Reynolds"],
      ["Tara", "Nguyen"],
      ["Chris", "Nguyen"],
      ["Leah", "Patel"],
      ["Jon", "Patel"],
      ["Erin", "Walker"],
      ["Miles", "Walker"],
      ["Dana", "Lopez"],
      ["Sam", "Lopez"],
      ["Noelle", "Brooks"],
      ["Gabe", "Brooks"],
      ["Sophie", "Reed"],
      ["Caleb", "Reed"],
      ["Nina", "Foster"]
    ],
    body_templates: [
      "Quick family update: we finally brought the baby home, everyone is healthy, and we are running almost entirely on frozen lasagna and coffee. We are tired, happy, and grateful.",
      "We spent the afternoon at Grandma's sorting old photo albums and found a stack of elementary school field day pictures. I forgot how aggressively competitive we all were about sack races.",
      "Small win from this week: the kitchen renovation is officially done, and we had our first dinner at the table without balancing plates on moving boxes.",
      "Posting a few photos from the backyard birthday dinner. Nothing fancy, just string lights, grilled corn, and the cousins staying up way too late catching fireflies.",
      "We had our follow-up appointment this morning and everything looked good. Thank you for all the meals, check-ins, and patient texts while we figured out our new normal.",
      "Heads up for anyone planning around summer: we booked the lake house for the second weekend in August. If you're thinking about coming, let me know so we can sort rooms early."
    ]
  },
  {
    name: "College Crew",
    description: "Old roommates and close friends keeping up with jobs, weddings, babies, and long-distance life.",
    member_names: [
      ["Alyssa", "Morgan"],
      ["Ben", "Morrison"],
      ["Priya", "Shah"],
      ["Jordan", "Lee"],
      ["Marcus", "Chen"],
      ["Tessa", "Howard"],
      ["Devon", "Clark"],
      ["Rachel", "Kim"],
      ["Nate", "Sullivan"],
      ["Hannah", "Price"],
      ["Luis", "Ortega"],
      ["Carly", "Dixon"],
      ["Zoe", "Barnes"],
      ["Theo", "Miller"],
      ["Maya", "Russell"]
    ],
    body_templates: [
      "Life update from our side: we signed a lease in Chicago and somehow managed to pack an entire apartment without ending the relationship. Move-in day is next Friday.",
      "Wedding planning report: venue is locked in, the guest list is still chaos, and we finally agreed on a band after listening to too many cover versions of 'September.'",
      "I uploaded a few photos from reunion weekend. It was mostly coffee, catching up, and realizing we all now talk about air fryers with the intensity we used to reserve for playlists.",
      "Work has been intense, so we took a last-minute cabin weekend with no signal and remembered what it feels like to sit on a porch without checking email every six minutes.",
      "Good news: after months of paperwork, our adoption home study is complete. Still more steps ahead, but this felt like a real milestone worth sharing with people who have been cheering us on.",
      "Throwing this in here before I forget: we are coming through town in June and would love to do a low-key backyard hang if enough people are around."
    ]
  },
  {
    name: "Maple Street Neighbors",
    description: "The block chat for porch concerts, lost packages, school pickups, and neighborhood events.",
    member_names: [
      ["Jenna", "Torres"],
      ["Mark", "Torres"],
      ["Olivia", "Grant"],
      ["Peter", "Grant"],
      ["Shelby", "Diaz"],
      ["Isaac", "Diaz"],
      ["Molly", "Hughes"],
      ["Derrick", "Hughes"],
      ["Paige", "Stewart"],
      ["Connor", "Stewart"],
      ["Rina", "Das"],
      ["Joel", "Das"],
      ["Katie", "Bell"],
      ["Aaron", "Bell"],
      ["Vivian", "Cole"]
    ],
    body_templates: [
      "Neighborhood heads-up: the city finally marked Maple for paving next Tuesday, so they asked everyone to keep cars off the street by 7 a.m.",
      "We put the extra tomatoes and cucumbers from the garden on the front porch in a basket. If you want them, take them before the sun turns them into soup.",
      "A package with baby formula was delivered to our house by mistake. If anyone on the block is waiting on a Target order, message me and I'll walk it over.",
      "Movie night in the cul-de-sac was a success. Kids made it halfway through before the younger ones turned the blanket pile into some kind of wrestling ring.",
      "Quick thank-you to whoever helped our dog back through the side gate this afternoon. He was muddy, proud of himself, and extremely uninterested in explaining where he had been.",
      "School pickup swap worked so well this week that we should probably make it a regular thing on early dismissal days."
    ]
  },
  {
    name: "Northside Soccer Parents",
    description: "Team parents coordinating rides, snack duty, tournaments, and every muddy Saturday.",
    member_names: [
      ["Katie", "Mendez"],
      ["Rob", "Mendez"],
      ["Allison", "Wright"],
      ["Darnell", "Wright"],
      ["Becca", "Holmes"],
      ["Sean", "Holmes"],
      ["Mina", "Park"],
      ["Owen", "Park"],
      ["Laura", "Bailey"],
      ["Tom", "Bailey"],
      ["Keisha", "Young"],
      ["Andre", "Young"],
      ["Megan", "Fitzpatrick"],
      ["Eric", "Fitzpatrick"],
      ["Sara", "Donovan"]
    ],
    body_templates: [
      "Game update: the kids looked sharp today and somehow kept their energy through both halves even with the heat. I posted the best goal clip because I know grandparents will want it.",
      "Reminder for this weekend's tournament: first game is at 8:15, parking is cash only, and the field map they sent is still wildly unhelpful, so give yourself extra time.",
      "Snack sign-up is full now. Thank you to everyone who volunteered because apparently our team can go through orange slices faster than any scientific model would predict.",
      "Coach sent the revised practice schedule and Wednesdays are back on. If anyone needs help with carpool juggling, we have two extra seats from the west side of town.",
      "The team photo proofs came in and the goofy outtakes are honestly better than the official one. I'll bring print order forms to practice.",
      "Shouting out the defense tonight because that second half was all hustle. The kids were muddy, freezing, and absolutely thrilled with themselves on the ride home."
    ]
  },
  {
    name: "Design Team Offsite",
    description: "Coworkers sharing project updates, travel plans, launches, and behind-the-scenes team life.",
    member_names: [
      ["Claire", "Bennett"],
      ["Omar", "Hassan"],
      ["Jess", "Collins"],
      ["Ryan", "Peters"],
      ["Anika", "Mehta"],
      ["Miles", "Harris"],
      ["Tori", "Adams"],
      ["Ben", "Alvarez"],
      ["Kayla", "Turner"],
      ["Wes", "Simmons"],
      ["Monica", "Yu"],
      ["Graham", "Ford"],
      ["Elena", "Rossi"],
      ["Noah", "Baker"],
      ["Simone", "Carter"]
    ],
    body_templates: [
      "Launch day update: the new onboarding flow is live, support volume stayed calm, and the bug we were bracing for never showed up. We are calling that a legitimate win.",
      "I dropped a few offsite photos in here because the whiteboard session somehow looked more dramatic than it felt in real time. Credit to the mountain view doing most of the work.",
      "Travel note for next month: my flight gets in late Wednesday, so if anyone is splitting a ride from the airport after 9 p.m. let me know.",
      "We wrapped user interviews this afternoon and the biggest surprise was how many people asked for simpler settings language. Feels like the next sprint just wrote itself.",
      "Quick personal update for the team friends in here: my partner and I are moving this weekend, so if I look slightly feral on Monday that is the explanation.",
      "Still laughing that the unofficial hit of the retreat was the breakfast burrito place across from the hotel and not the carefully planned welcome dinner."
    ]
  }
].freeze

CHILD_POOL = [
  ["Ava", 7],
  ["Eli", 4],
  ["Nora", 2],
  ["Theo", 9],
  ["Lucy", 5],
  ["Mason", 3],
  ["Hazel", 6],
  ["Ivy", 1],
  ["Leo", 8],
  ["Ruby", 10]
].freeze

STREET_NAMES = [
  "Maple Avenue",
  "Willow Lane",
  "Cedar Street",
  "Riverside Drive",
  "Franklin Court",
  "Highland Road",
  "Oakview Terrace",
  "Summit Place"
].freeze

POST_TAGLINES = [
  "sharing a few photos here",
  "dropping this here for the group",
  "wanted this in one place for everyone"
].freeze

def sample_date(year_offset:, month:, day:)
  Date.new(Date.current.year - year_offset, month, day)
end

def demo_email(first_name, last_name)
  "#{first_name.downcase}.#{last_name.downcase}@#{EMAIL_DOMAIN}"
end

def address_for(index)
  "#{120 + index} #{STREET_NAMES[index % STREET_NAMES.length]}\nBrookhaven, NY 11719"
end

def notes_for(group_name, index)
  case group_name
  when "Sunday Family Loop"
    [
      "Prefers weekend calls after nap time.",
      "Usually has the latest family calendar details.",
      "Loves getting photo updates and milestone notes."
    ][index % 3]
  when "College Crew"
    [
      "Always the first to suggest a reunion date.",
      "Keeps track of birthdays better than the rest of us.",
      "Often shares travel plans and life updates here first."
    ][index % 3]
  when "Maple Street Neighbors"
    [
      "Good backup contact for school pickup swaps.",
      "Usually knows which contractor everyone on the block recommends.",
      "Most likely to organize a last-minute porch hang."
    ][index % 3]
  when "Northside Soccer Parents"
    [
      "Helpful for carpool coordination.",
      "Usually has extra snacks and folding chairs.",
      "Quick to share game photos with the team."
    ][index % 3]
  else
    [
      "Frequent offsite planner and photo taker.",
      "Usually posts team logistics before anyone asks.",
      "Shares project wins and life updates in equal measure."
    ][index % 3]
  end
end

def spouse_name_for(index)
  spouses = %w[
    Alex
    Jamie
    Taylor
    Jordan
    Morgan
    Casey
    Riley
    Cameron
  ]
  spouses[index % spouses.length]
end

def create_children_for(user, index)
  child_count = case index % 5
                when 0 then 2
                when 1 then 1
                else 0
                end

  return if child_count.zero?

  child_count.times do |child_index|
    name, age = CHILD_POOL[(index + child_index) % CHILD_POOL.length]
    birthday = Date.current - age.years - ((child_index + 2) * 17).days

    user.children.create!(
      name: name,
      age: age,
      birthday: birthday,
      notes: ["Loves dinosaurs.", "Currently into soccer.", "Never says no to popsicles."][child_index % 3]
    )
  end
end

def create_post_for(user:, group:, body:, created_at:)
  post = user.posts.create!(
    body: body,
    created_at: created_at,
    updated_at: created_at
  )

  PostGroup.create!(
    post_id: post.id,
    group_id: group.id,
    created_at: created_at,
    updated_at: created_at
  )
end

seed_group_names = GROUP_DEFINITIONS.pluck(:name)
seed_emails = GROUP_DEFINITIONS.flat_map do |definition|
  definition[:member_names].map { |first_name, last_name| demo_email(first_name, last_name) }
end

Invitation.where(group: Group.where(name: seed_group_names)).delete_all
Invitation.where(inviter: User.where(email: seed_emails)).delete_all
Invitation.where(invited_user: User.where(email: seed_emails)).delete_all
PostGroup.joins(:group).where(groups: { name: seed_group_names }).delete_all
Membership.joins(:group).where(groups: { name: seed_group_names }).delete_all
Group.where(name: seed_group_names).delete_all
User.where(email: seed_emails).find_each do |user|
  user.posts.find_each(&:destroy!)
  user.destroy!
end

PostGroup.skip_callback(:commit, :after, :refresh_group_summary, on: %i[create destroy])

begin
  GROUP_DEFINITIONS.each_with_index do |definition, group_index|
    group = Group.create!(
      name: definition[:name],
      description: "#{definition[:description]} #{SUMMARY_TEXT}"
    )

    definition[:member_names].each_with_index do |(first_name, last_name), member_index|
      email = demo_email(first_name, last_name)
      user = User.create!(
        email: email,
        password: PASSWORD,
        password_confirmation: PASSWORD,
        first_name: first_name,
        last_name: last_name,
        birthday: sample_date(year_offset: 28 + ((group_index + member_index) % 12), month: ((member_index % 12) + 1), day: [member_index + 1, 28].min),
        spouse_name: member_index.even? ? spouse_name_for(group_index + member_index) : nil,
        spouse_birthday: member_index.even? ? sample_date(year_offset: 27 + ((member_index + 2) % 10), month: (((member_index + 4) % 12) + 1), day: [member_index + 3, 28].min) : nil,
        home_address: address_for((group_index * 20) + member_index),
        contact_notes: notes_for(group.name, member_index),
        confirmed_at: Time.current
      )

      create_children_for(user, group_index + member_index)

      Membership.create!(
        user: user,
        group: group,
        role: member_index.zero? ? :admin : :member
      )

      3.times do |post_index|
        body_template = definition[:body_templates][(member_index + post_index) % definition[:body_templates].length]
        time_offset = ((group_index * 45) + (member_index * 3) + post_index).days
        created_at = Time.current - time_offset

        body = [
          body_template,
          "From #{first_name}'s corner: #{POST_TAGLINES[post_index % POST_TAGLINES.length]}.",
          post_index == 2 ? "Looking forward to hearing how everyone else is doing when you have a minute." : nil
        ].compact.join(" ")

        create_post_for(user: user, group: group, body: body, created_at: created_at)
      end
    end
  end
ensure
  PostGroup.set_callback(:commit, :after, :refresh_group_summary, on: %i[create destroy])
end

seeded_group_count = Group.where(name: seed_group_names).count
seeded_user_count = User.where(email: seed_emails).count
seeded_membership_count = Membership.joins(:group).where(groups: { name: seed_group_names }).count
seeded_post_count = Post.joins(:user).where(users: { email: seed_emails }).count

Rails.logger.debug { "Seeded #{seeded_group_count} groups, #{seeded_user_count} users, #{seeded_membership_count} memberships, and #{seeded_post_count} posts." }
