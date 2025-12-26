// ignore_for_file: lines_longer_than_80_chars

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

/// List of categories of emojis
const List<CategoryEmoji> emojiSetEnglish = [
// ======================================================= Category.SMILEYS
  CategoryEmoji(Category.SMILEYS, [
    Emoji(
      'ðŸ˜€',
      'cheerful | cheery | face | grin | grinning | happy | laugh | nice | smile | smiling | teeth',
    ),
    Emoji(
      'ðŸ˜ƒ',
      'awesome | big | eyes | face | grin | grinning | happy | mouth | open | smile | smiling | teeth | yay',
    ),
    Emoji(
      'ðŸ˜„',
      'eye | eyes | face | grin | grinning | happy | laugh | lol | mouth | open | smile | smiling',
    ),
    Emoji(
      'ðŸ˜',
      'beaming | eye | eyes | face | grin | grinning | happy | nice | smile | smiling | teeth',
    ),
    Emoji(
      'ðŸ˜†',
      'closed | eyes | face | grinning | haha | hahaha | happy | laugh | lol | mouth | open | rofl | smile | smiling | squinting',
    ),
    Emoji(
      'ðŸ˜…',
      'cold | dejected | excited | face | grinning | mouth | nervous | open | smile | smiling | stress | stressed | sweat',
    ),
    Emoji(
      'ðŸ¤£',
      'crying | face | floor | funny | haha | happy | hehe | hilarious | joy | laugh | lmao | lol | rofl | roflmao | rolling | tear',
    ),
    Emoji(
      'ðŸ˜‚',
      'crying | face | feels | funny | haha | happy | hehe | hilarious | joy | laugh | lmao | lol | rofl | roflmao | tear',
    ),
    Emoji(
      'ðŸ™‚',
      'face | happy | slightly | smile | smiling',
    ),
    Emoji(
      'ðŸ™ƒ',
      'face | hehe | smile | upside-down',
    ),
    Emoji(
      'ðŸ˜‰',
      'face | flirt | heartbreaker | sexy | slide | tease | wink | winking | winks',
    ),
    Emoji(
      'ðŸ˜Š',
      'blush | eye | eyes | face | glad | satisfied | smile | smiling',
    ),
    Emoji(
      'ðŸ˜‡',
      'angel | angelic | angels | blessed | face | fairy | fairytale | fantasy | halo | happy | innocent | peaceful | smile | smiling | spirit | tale',
    ),
    Emoji(
      'ðŸ¥°',
      '3 | adore | crush | face | heart | hearts | ily | love | romance | smile | smiling | you',
    ),
    Emoji(
      'ðŸ˜',
      '143 | bae | eye | face | feels | heart-eyes | hearts | ily | kisses | love | romance | romantic | smile | xoxo',
    ),
    Emoji(
      'ðŸ¤©',
      'excited | eyes | face | grinning | smile | star | star-struck | starry-eyed | wow',
    ),
    Emoji(
      'ðŸ˜˜',
      'adorbs | bae | blowing | face | flirt | heart | ily | kiss | love | lover | miss | muah | romantic | smooch | xoxo | you',
    ),
    Emoji(
      'ðŸ˜—',
      '143 | date | dating | face | flirt | ily | kiss | love | smooch | smooches | xoxo | you',
    ),
    Emoji(
      'â˜ºï¸',
      'face | happy | outlined | relaxed | smile | smiling ',
    ),
    Emoji(
      'ðŸ˜š',
      '143 | bae | blush | closed | date | dating | eye | eyes | face | flirt | ily | kisses | kissing | smooches | xoxo',
    ),
    Emoji(
      'ðŸ˜™',
      '143 | closed | date | dating | eye | eyes | face | flirt | ily | kiss | kisses | kissing | love | night | smile | smiling',
    ),
    Emoji(
      'ðŸ˜‹',
      'delicious | eat | face | food | full | hungry | savor | smile | smiling | tasty | um | yum | yummy',
    ),
    Emoji(
      'ðŸ˜›',
      'awesome | cool | face | nice | party | stuck-out | sweet | tongue',
    ),
    Emoji(
      'ðŸ˜œ',
      'crazy | epic | eye | face | funny | joke | loopy | nutty | party | stuck-out | tongue | wacky | weirdo | wink | winking | yolo',
    ),
    Emoji(
      'ðŸ¤ª',
      'crazy | eye | eyes | face | goofy | large | small | zany',
    ),
    Emoji(
      'ðŸ˜',
      'closed | eye | eyes | face | gross | horrible | omg | squinting | stuck-out | taste | tongue | whatever | yolo',
    ),
    Emoji(
      'ðŸ¤‘',
      'face | money | money-mouth | mouth | paid',
    ),
    Emoji(
      'ðŸ¤—',
      'face | hands | hug | hugging | open | smiling',
    ),
    Emoji(
      'ðŸ«£',
      'captivated | embarrass | eye | face | hide | hiding | peek | peeking | peep | scared | shy | stare',
    ),
    Emoji(
      'ðŸ¤­',
      'face | giggle | giggling | hand | mouth | oops | realization | secret | shock | sudden | surprise | whoops',
    ),
    Emoji(
      'ðŸ«¢',
      'amazement | awe | disbelief | embarrass | eyes | face | gasp | hand | mouth | omg | open | over | quiet | scared | shock | surprise',
    ),
    Emoji(
      'ðŸ«¡',
      'face | good | luck | maâ€™am | OK | respect | salute | saluting | sir | troops | yes',
    ),
    Emoji(
      'ðŸ¤«',
      'face | quiet | shh | shush | shushing',
    ),
    Emoji(
      'ðŸ« ',
      'disappear | dissolve | embarrassed | face | haha | heat | hot | liquid | lol | melt | melting | sarcasm | sarcastic',
    ),
    Emoji(
      'ðŸ¤”',
      'chin | consider | face | hmm | ponder | pondering | thinking | wondering',
    ),
    Emoji(
      'ðŸ¤',
      'face | keep | mouth | quiet | secret | shut | zip | zipper | zipper-mouth',
    ),
    Emoji(
      'ðŸ¤¨',
      'disapproval | disbelief | distrust | emoji | eyebrow | face | hmm | mild | raised | skeptic | skeptical | skepticism | surprise | what',
    ),
    Emoji(
      'ðŸ˜',
      'awkward | blank | deadpan | expressionless | face | fine | jealous | meh | neutral | oh | shade | straight | unamused | unhappy | unimpressed | whatever',
    ),
    Emoji(
      'ðŸ«¤',
      'confused | confusion | diagonal | disappointed | doubt | doubtful | face | frustrated | frustration | meh | mouth | skeptical | unsure | whatever | wtv',
    ),
    Emoji(
      'ðŸ˜‘',
      'awkward | dead | expressionless | face | fine | inexpressive | jealous | meh | not | oh | omg | straight | uh | unhappy | unimpressed | whatever',
    ),
    Emoji(
      'ðŸ˜¶',
      'awkward | blank | expressionless | face | mouth | mouthless | mute | quiet | secret | silence | silent | speechless',
    ),
    Emoji(
      'ðŸ«¥',
      'depressed | disappear | dotted | face | hidden | hide | introvert | invisible | line | meh | whatever | wtv',
    ),
    Emoji(
      'ðŸ˜',
      'boss | dapper | face | flirt | homie | kidding | leer | shade | slick | sly | smirk | smug | snicker | suave | suspicious | swag',
    ),
    Emoji(
      'ðŸ˜’',
      '... | bored | face | fine | jealous | jel | jelly | pissed | smh | ugh | uhh | unamused | unhappy | weird | whatever',
    ),
    Emoji(
      'ðŸ™„',
      'eyeroll | eyes | face | rolling | shade | ugh | whatever',
    ),
    Emoji(
      'ðŸ˜¬',
      'awk | awkward | dentist | face | grimace | grimacing | grinning | smile | smiling',
    ),
    Emoji(
      'ðŸ¤¥',
      'face | liar | lie | lying | pinocchio',
    ),
    Emoji(
      'ðŸ˜Œ',
      'calm | face | peace | relief | relieved | zen',
    ),
    Emoji(
      'ðŸ˜”',
      'awful | bored | dejected | died | disappointed | face | losing | lost | pensive | sad | sucks',
    ),
    Emoji(
      'ðŸ¥¹',
      'admiration | aww | back | cry | embarrassed | face | feelings | grateful | gratitude | holding | joy | please | proud | resist | sad | tears',
    ),
    Emoji(
      'ðŸ˜ª',
      'crying | face | good | night | sad | sleep | sleeping | sleepy | tired',
    ),
    Emoji(
      'ðŸ¤¤',
      'drooling | face',
    ),
    Emoji(
      'ðŸ˜´',
      'bed | bedtime | face | good | goodnight | nap | night | sleep | sleeping | tired | whatever | yawn | zzz',
    ),
    Emoji(
      'ðŸ˜·',
      'cold | dentist | dermatologist | doctor | dr | face | germs | mask | medical | medicine | sick',
    ),
    Emoji(
      'ðŸ¤’',
      'face | ill | sick | thermometer',
    ),
    Emoji(
      'ðŸ¤•',
      'bandage | face | head-bandage | hurt | injury | ouch',
    ),
    Emoji(
      'ðŸ¤¢',
      'face | gross | nasty | nauseated | sick | vomit',
    ),
    Emoji(
      'ðŸ¤®',
      'barf | ew | face | gross | puke | sick | spew | throw | up | vomit | vomiting',
    ),
    Emoji(
      'ðŸ¤§',
      'face | fever | flu | gesundheit | sick | sneeze | sneezing',
    ),
    Emoji(
      'ðŸ¥µ',
      'dying | face | feverish | heat | hot | panting | red-faced | stroke | sweating | tongue',
    ),
    Emoji(
      'ðŸ¥¶',
      'blue | blue-faced | cold | face | freezing | frostbite | icicles | subzero | teeth',
    ),
    Emoji(
      'ðŸ¥´',
      'dizzy | drunk | eyes | face | intoxicated | mouth | tipsy | uneven | wavy | woozy',
    ),
    Emoji(
      'ðŸ˜µ',
      'crossed-out | dead | dizzy | eyes | face | feels | knocked | out | sick | tired',
    ),
    Emoji(
      'ðŸ˜µâ€ðŸ’«',
      'confused | dizzy | eyes | face | hypnotized | omg | smiley | spiral | trouble | whoa | woah | woozy',
    ),
    Emoji(
      'ðŸ¤¯',
      'blown | explode | exploding | head | mind | mindblown | no | shocked | way',
    ),
    Emoji(
      'ðŸ¤ ',
      'cowboy | cowgirl | face | hat',
    ),
    Emoji(
      'ðŸ¥³',
      'bday | birthday | celebrate | celebration | excited | face | happy | hat | hooray | horn | party | partying',
    ),
    Emoji(
      'ðŸ˜Ž',
      'awesome | beach | bright | bro | chilling | cool | face | rad | relaxed | shades | slay | smile | style | sunglasses | swag | win',
    ),
    Emoji(
      'ðŸ¤“',
      'brainy | clever | expert | face | geek | gifted | glasses | intelligent | nerd | smart',
    ),
    Emoji(
      'ðŸ§',
      'classy | face | fancy | monocle | rich | stuffy | wealthy',
    ),
    Emoji(
      'ðŸ˜•',
      'befuddled | confused | confusing | dunno | face | frown | hm | meh | not | sad | sorry | sure',
    ),
    Emoji(
      'ðŸ˜Ÿ',
      'anxious | butterflies | face | nerves | nervous | sad | stress | stressed | surprised | worried | worry',
    ),
    Emoji(
      'ðŸ™',
      'face | frown | frowning | sad | slightly',
    ),
    Emoji(
      'â˜¹ï¸',
      'face | frown | frowning | sad ',
    ),
    Emoji(
      'ðŸ˜®',
      'believe | face | forgot | mouth | omg | open | shocked | surprised | sympathy | unbelievable | unreal | whoa | wow | you',
    ),
    Emoji(
      'ðŸ˜¯',
      'epic | face | hushed | omg | stunned | surprised | whoa | woah',
    ),
    Emoji(
      'ðŸ˜²',
      'astonished | cost | face | no | omg | shocked | totally | way',
    ),
    Emoji(
      'ðŸ˜³',
      'amazed | awkward | crazy | dazed | dead | disbelief | embarrassed | face | flushed | geez | heat | hot | impressed | jeez | what | wow',
    ),
    Emoji(
      'ðŸ¥º',
      'begging | big | eyes | face | mercy | not | pleading | please | pretty | puppy | sad | why',
    ),
    Emoji(
      'ðŸ˜¦',
      'caught | face | frown | frowning | guard | mouth | open | scared | scary | surprise | what | wow',
    ),
    Emoji(
      'ðŸ˜§',
      'anguished | face | forgot | scared | scary | stressed | surprise | unhappy | what | wow',
    ),
    Emoji(
      'ðŸ˜¨',
      'afraid | anxious | blame | face | fear | fearful | scared | worried',
    ),
    Emoji(
      'ðŸ˜°',
      'anxious | blue | cold | eek | face | mouth | nervous | open | rushed | scared | sweat | yikes',
    ),
    Emoji(
      'ðŸ˜¥',
      'anxious | call | close | complicated | disappointed | face | not | relieved | sad | sweat | time | whew',
    ),
    Emoji(
      'ðŸ˜¢',
      'awful | cry | crying | face | feels | miss | sad | tear | triste | unhappy',
    ),
    Emoji(
      'ðŸ˜­',
      'bawling | cry | crying | face | loudly | sad | sob | tear | tears | unhappy',
    ),
    Emoji(
      'ðŸ˜±',
      'epic | face | fear | fearful | munch | scared | scream | screamer | screaming | shocked | surprised | woah',
    ),
    Emoji(
      'ðŸ˜–',
      'annoyed | confounded | confused | cringe | distraught | face | feels | frustrated | mad | sad',
    ),
    Emoji(
      'ðŸ˜£',
      'concentrate | concentration | face | focus | headache | persevere | persevering',
    ),
    Emoji(
      'ðŸ˜ž',
      'awful | blame | dejected | disappointed | face | fail | losing | sad | unhappy',
    ),
    Emoji(
      'ðŸ˜“',
      'close | cold | downcast | face | feels | headache | nervous | sad | scared | sweat | yikes',
    ),
    Emoji(
      'ðŸ˜©',
      'crying | face | fail | feels | hungry | mad | nooo | sad | sleepy | tired | unhappy | weary',
    ),
    Emoji(
      'ðŸ˜«',
      'cost | face | feels | nap | sad | sneeze | tired',
    ),
    Emoji(
      'ðŸ˜¤',
      'anger | angry | face | feels | fume | fuming | furious | fury | mad | nose | steam | triumph | unhappy | won',
    ),
    Emoji(
      'ðŸ˜¡',
      'anger | angry | enraged | face | feels | mad | maddening | pouting | rage | red | shade | unhappy | upset',
    ),
    Emoji(
      'ðŸ˜ ',
      'anger | angry | blame | face | feels | frustrated | mad | maddening | rage | shade | unhappy | upset',
    ),
    Emoji(
      'ðŸ¤¬',
      'censor | cursing | cussing | face | mad | mouth | pissed | swearing | symbols',
    ),
    Emoji(
      'ðŸ˜ˆ',
      'demon | devil | evil | face | fairy | fairytale | fantasy | horns | purple | shade | smile | smiling | tale',
    ),
    Emoji(
      'ðŸ‘¿',
      'angry | demon | devil | evil | face | fairy | fairytale | fantasy | horns | imp | mischievous | purple | shade | tale',
    ),
    Emoji(
      'ðŸ’€',
      'body | dead | death | face | fairy | fairytale | iâ€™m | lmao | monster | skull | tale | yolo',
    ),
    Emoji(
      'â˜ ï¸',
      'bone | crossbones | dead | death | face | monster | skull ',
    ),
    Emoji(
      'ðŸ’©',
      'bs | comic | doo | dung | face | fml | monster | pile | poo | poop | smelly | smh | stink | stinks | stinky | turd',
    ),
    Emoji(
      'ðŸ¤¡',
      'clown | face',
    ),
    Emoji(
      'ðŸ‘¹',
      'creature | devil | face | fairy | fairytale | fantasy | mask | monster | ogre | scary | tale',
    ),
    Emoji(
      'ðŸ‘º',
      'angry | creature | face | fairy | fairytale | fantasy | goblin | mask | mean | monster | tale',
    ),
    Emoji(
      'ðŸ‘»',
      'boo | creature | excited | face | fairy | fairytale | fantasy | ghost | halloween | haunting | monster | scary | silly | tale',
    ),
    Emoji(
      'ðŸ‘½',
      'alien | creature | extraterrestrial | face | fairy | fairytale | fantasy | monster | space | tale | ufo',
    ),
    Emoji(
      'ðŸ‘¾',
      'alien | creature | extraterrestrial | face | fairy | fairytale | fantasy | game | gamer | games | monster | pixelated | space | tale | ufo',
    ),
    Emoji(
      'ðŸ¤–',
      'face | monster | robot',
    ),
    Emoji(
      'ðŸŽƒ',
      'celebration | halloween | jack | jack-o-lantern | lantern | pumpkin',
    ),
    Emoji(
      'ðŸ˜º',
      'animal | cat | face | grinning | mouth | open | smile | smiling',
    ),
    Emoji(
      'ðŸ˜¸',
      'animal | cat | eye | eyes | face | grin | grinning | smile | smiling',
    ),
    Emoji(
      'ðŸ˜¹',
      'animal | cat | face | joy | laugh | laughing | lol | tear | tears',
    ),
    Emoji(
      'ðŸ˜»',
      'animal | cat | eye | face | heart | heart-eyes | love | smile | smiling',
    ),
    Emoji(
      'ðŸ˜¼',
      'animal | cat | face | ironic | smile | wry',
    ),
    Emoji(
      'ðŸ˜½',
      'animal | cat | closed | eye | eyes | face | kiss | kissing',
    ),
    Emoji(
      'ðŸ™€',
      'animal | cat | face | oh | surprised | weary',
    ),
    Emoji(
      'ðŸ˜¿',
      'animal | cat | cry | crying | face | sad | tear',
    ),
    Emoji(
      'ðŸ˜¾',
      'animal | cat | face | pouting',
    ),
    Emoji('ðŸ«¶', '<3 | hands | heart | love | you', hasSkinTone: true),
    Emoji('ðŸ‘‹',
        'bye | cya | g2g | greetings | gtg | hand | hello | hey | hi | later | outtie | ttfn | ttyl | wave | yo | you',
        hasSkinTone: true),
    Emoji('ðŸ¤š', 'back | backhand | hand | raised', hasSkinTone: true),
    Emoji('ðŸ–ï¸', 'finger | fingers | hand | raised | splayed | stop ',
        hasSkinTone: true),
    Emoji('âœ‹', '5 | five | hand | high | raised | stop', hasSkinTone: true),
    Emoji('ðŸ––', 'finger | hand | hands | salute | Vulcan', hasSkinTone: true),
    Emoji('ðŸ‘Œ',
        'awesome | bet | dope | fleek | fosho | got | gotcha | hand | legit | OK | okay | pinch | rad | sure | sweet | three',
        hasSkinTone: true),
    Emoji('ðŸ¤Œ',
        'fingers | gesture | hand | hold | huh | interrogation | patience | pinched | relax | sarcastic | ugh | what | zip',
        hasSkinTone: true),
    Emoji('ðŸ¤',
        'amount | bit | fingers | hand | little | pinching | small | sort',
        hasSkinTone: true),
    Emoji('ðŸ«³',
        'dismiss | down | drop | dropped | hand | palm | pick | shoo | up',
        hasSkinTone: true),
    Emoji('ðŸ«´',
        'beckon | catch | come | hand | hold | know | lift | me | offer | palm | tell',
        hasSkinTone: true),
    Emoji('âœŒï¸', 'hand | peace | v | victory ', hasSkinTone: true),
    Emoji('ðŸ«°',
        '<3 | crossed | expensive | finger | hand | heart | index | love | money | snap | thumb',
        hasSkinTone: true),
    Emoji('ðŸ¤ž', 'cross | crossed | finger | fingers | hand | luck',
        hasSkinTone: true),
    Emoji(
        'ðŸ¤Ÿ', 'fingers | gesture | hand | ILY | love | love-you | three | you',
        hasSkinTone: true),
    Emoji('ðŸ¤˜', 'finger | hand | horns | rock-on | sign', hasSkinTone: true),
    Emoji('ðŸ¤™', 'call | hand | hang | loose | me | Shaka', hasSkinTone: true),
    Emoji('ðŸ‘ˆ', 'backhand | finger | hand | index | left | point | pointing',
        hasSkinTone: true),
    Emoji('ðŸ‘‰', 'backhand | finger | hand | index | point | pointing | right',
        hasSkinTone: true),
    Emoji('ðŸ‘†', 'backhand | finger | hand | index | point | pointing | up',
        hasSkinTone: true),
    Emoji('ðŸ–•', 'finger | hand | middle', hasSkinTone: true),
    Emoji('ðŸ‘‡', 'backhand | down | finger | hand | index | point | pointing',
        hasSkinTone: true),
    Emoji('â˜ï¸', 'finger | hand | index | point | pointing | this | up ',
        hasSkinTone: true),
    Emoji('ðŸ‘', '+1 | good | hand | like | thumb | up | yes',
        hasSkinTone: true),
    Emoji('ðŸ‘Ž',
        '-1 | bad | dislike | down | good | hand | no | nope | thumb | thumbs',
        hasSkinTone: true),
    Emoji('âœŠ', 'clenched | fist | hand | punch | raised | solidarity',
        hasSkinTone: true),
    Emoji('ðŸ‘Š',
        'absolutely | agree | boom | bro | bruh | bump | clenched | correct | fist | hand | knuckle | oncoming | pound | punch | rock | ttyl',
        hasSkinTone: true),
    Emoji('ðŸ¤›', 'fist | left-facing | leftwards', hasSkinTone: true),
    Emoji('ðŸ¤œ', 'fist | right-facing | rightwards', hasSkinTone: true),
    Emoji('ðŸ«²',
        'hand | handshake | hold | left | leftward | leftwards | reach | shake',
        hasSkinTone: true),
    Emoji('ðŸ«±',
        'hand | handshake | hold | reach | right | rightward | rightwards | shake',
        hasSkinTone: true),
    Emoji('ðŸ‘',
        'applause | approval | awesome | clap | congrats | congratulations | excited | good | great | hand | homie | job | nice | prayed | well | yay',
        hasSkinTone: true),
    Emoji('ðŸ™Œ',
        'celebration | gesture | hand | hands | hooray | praise | raised | raising',
        hasSkinTone: true),
    Emoji('ðŸ‘', 'hand | hands | hug | jazz | open | swerve', hasSkinTone: true),
    Emoji('ðŸ¤²',
        'cupped | dua | hands | palms | pray | prayer | together | up | wish',
        hasSkinTone: true),
    Emoji('ðŸ¤', 'agreement | deal | hand | handshake | meeting | shake',
        hasSkinTone: true),
    Emoji('ðŸ™',
        'appreciate | ask | beg | blessed | bow | cmon | five | folded | gesture | hand | high | please | pray | thanks | thx',
        hasSkinTone: true),
    Emoji('ðŸ«µ', 'at | finger | hand | index | pointing | poke | viewer | you',
        hasSkinTone: true),
    Emoji('âœï¸', 'hand | write | writing ', hasSkinTone: true),
    Emoji('ðŸ’…',
        'bored | care | cosmetics | done | makeup | manicure | nail | polish | whatever',
        hasSkinTone: true),
    Emoji('ðŸ¤³', 'camera | phone | selfie', hasSkinTone: true),
    Emoji('ðŸ’ª',
        'arm | beast | bench | biceps | bodybuilder | bro | curls | flex | gains | gym | jacked | muscle | press | ripped | strong | weightlift',
        hasSkinTone: true),
    Emoji('ðŸ¦µ', 'bent | foot | kick | knee | leg | limb', hasSkinTone: true),
    Emoji('ðŸ¦¶', 'ankle | feet | foot | kick | stomp', hasSkinTone: true),
    Emoji(
        'ðŸ‘‚', 'body | ear | ears | hear | hearing | listen | listening | sound',
        hasSkinTone: true),
    Emoji('ðŸ‘ƒ', 'body | nose | noses | nosey | odor | smell | smells',
        hasSkinTone: true),
    Emoji(
      'ðŸ§ ',
      'brain | intelligent | smart',
    ),
    Emoji(
      'ðŸ¦´',
      'bone | bones | dog | skeleton | wishbone',
    ),
    Emoji(
      'ðŸ‘€',
      'body | eye | eyes | face | googly | look | looking | omg | peep | see | seeing',
    ),
    Emoji(
      'ðŸ‘ï¸',
      '1 | body | eye | one ',
    ),
    Emoji(
      'ðŸ’‹',
      'dating | emotion | heart | kiss | kissing | lips | mark | romance | sexy',
    ),
    Emoji(
      'ðŸ‘„',
      'beauty | body | kiss | kissing | lips | lipstick | mouth',
    ),
    Emoji(
      'ðŸ«¦',
      'anxious | bite | biting | fear | flirt | flirting | kiss | lip | lipstick | nervous | sexy | uncomfortable | worried | worry',
    ),
    Emoji(
      'ðŸ¦·',
      'dentist | pearly | teeth | tooth | white',
    ),
    Emoji(
      'ðŸ‘…',
      'body | lick | slurp | tongue',
    ),
    Emoji('ðŸ‘¶',
        'babies | baby | children | goo | infant | newborn | pregnant | young',
        hasSkinTone: true),
    Emoji('ðŸ§’', 'bright-eyed | child | grandchild | kid | young | younger',
        hasSkinTone: true),
    Emoji('ðŸ‘¦',
        'boy | bright-eyed | child | grandson | kid | son | young | younger',
        hasSkinTone: true),
    Emoji('ðŸ‘§',
        'bright-eyed | child | daughter | girl | granddaughter | kid | Virgo | young | younger | zodiac',
        hasSkinTone: true),
    Emoji('ðŸ§‘', 'adult | person', hasSkinTone: true),
    Emoji('ðŸ‘¨', 'adult | bro | man', hasSkinTone: true),
    Emoji('ðŸ§”', 'beard | bearded | person | whiskers', hasSkinTone: true),
    Emoji('ðŸ‘±', 'blond | blond-haired | human | person', hasSkinTone: true),
    Emoji('ðŸ‘¨â€ðŸ¦°', 'adult | bro | man ginger | hair | red | redhead ',
        hasSkinTone: true),
    Emoji('ðŸ‘¨â€ðŸ¦±', 'adult | bro | man afro | curly | hair | ringlets ',
        hasSkinTone: true),
    Emoji('ðŸ‘¨â€ðŸ¦³', 'adult | bro | man gray | hair | old | white ',
        hasSkinTone: true),
    Emoji('ðŸ‘¨â€ðŸ¦²',
        'adult | bro | man bald | chemotherapy | hair | hairless | no | shaven ',
        hasSkinTone: true),
    Emoji('ðŸ‘©', 'adult | lady | woman', hasSkinTone: true),
    Emoji(
        'ðŸ‘±â€â™€ï¸', 'blond | blond-haired | human | person female | sign | woman ',
        hasSkinTone: true),
    Emoji('ðŸ‘©â€ðŸ¦°', 'adult | lady | woman ginger | hair | red | redhead ',
        hasSkinTone: true),
    Emoji('ðŸ‘©â€ðŸ¦±', 'adult | lady | woman afro | curly | hair | ringlets ',
        hasSkinTone: true),
    Emoji('ðŸ‘©â€ðŸ¦³', 'adult | lady | woman gray | hair | old | white ',
        hasSkinTone: true),
    Emoji('ðŸ‘©â€ðŸ¦²',
        'adult | lady | woman bald | chemotherapy | hair | hairless | no | shaven ',
        hasSkinTone: true),
    Emoji('ðŸ§“', 'adult | elderly | grandparent | old | person | wise',
        hasSkinTone: true),
    Emoji('ðŸ‘´',
        'adult | bald | elderly | gramps | grandfather | grandpa | man | old | wise',
        hasSkinTone: true),
    Emoji('ðŸ‘µ',
        'adult | elderly | grandma | grandmother | granny | lady | old | wise | woman',
        hasSkinTone: true),
    Emoji('ðŸ™â€â™‚ï¸',
        'annoyed | disappointed | disgruntled | disturbed | frown | frowning | frustrated | gesture | irritated | person | upset male | man | sign ',
        hasSkinTone: true),
    Emoji('ðŸ™â€â™€ï¸',
        'annoyed | disappointed | disgruntled | disturbed | frown | frowning | frustrated | gesture | irritated | person | upset female | sign | woman ',
        hasSkinTone: true),
    Emoji('ðŸ™Žâ€â™‚ï¸',
        'disappointed | downtrodden | frown | grimace | person | pouting | scowl | sulk | upset | whine male | man | sign ',
        hasSkinTone: true),
    Emoji('ðŸ™Žâ€â™€ï¸',
        'disappointed | downtrodden | frown | grimace | person | pouting | scowl | sulk | upset | whine female | sign | woman ',
        hasSkinTone: true),
    Emoji('ðŸ™…â€â™‚ï¸',
        'forbidden | gesture | hand | NO | not | person | prohibit male | man | sign ',
        hasSkinTone: true),
    Emoji('ðŸ™…â€â™€ï¸',
        'forbidden | gesture | hand | NO | not | person | prohibit female | sign | woman ',
        hasSkinTone: true),
    Emoji('ðŸ™†â€â™‚ï¸',
        'exercise | gesture | gesturing | hand | OK | omg | person male | man | sign ',
        hasSkinTone: true),
    Emoji('ðŸ™†â€â™€ï¸',
        'exercise | gesture | gesturing | hand | OK | omg | person female | sign | woman ',
        hasSkinTone: true),
    Emoji('ðŸ’â€â™‚ï¸',
        'fetch | flick | flip | gossip | hand | person | sarcasm | sarcastic | sassy | seriously | tipping | whatever male | man | sign ',
        hasSkinTone: true),
    Emoji('ðŸ’â€â™€ï¸',
        'fetch | flick | flip | gossip | hand | person | sarcasm | sarcastic | sassy | seriously | tipping | whatever female | sign | woman ',
        hasSkinTone: true),
    Emoji('ðŸ™‹â€â™‚ï¸',
        'gesture | hand | here | know | me | person | pick | question | raise | raising male | man | sign ',
        hasSkinTone: true),
    Emoji('ðŸ™‹â€â™€ï¸',
        'gesture | hand | here | know | me | person | pick | question | raise | raising female | sign | woman ',
        hasSkinTone: true),
    Emoji('ðŸ™‡â€â™‚ï¸',
        'apology | ask | beg | bow | bowing | favor | forgive | gesture | meditate | meditation | person | pity | regret | sorry male | man | sign ',
        hasSkinTone: true),
    Emoji('ðŸ™‡â€â™€ï¸',
        'apology | ask | beg | bow | bowing | favor | forgive | gesture | meditate | meditation | person | pity | regret | sorry female | sign | woman ',
        hasSkinTone: true),
    Emoji('ðŸ¤¦â€â™‚ï¸',
        'again | bewilder | disbelief | exasperation | facepalm | no | not | oh | omg | person | shock | smh male | man | sign ',
        hasSkinTone: true),
    Emoji('ðŸ¤¦â€â™€ï¸',
        'again | bewilder | disbelief | exasperation | facepalm | no | not | oh | omg | person | shock | smh female | sign | woman ',
        hasSkinTone: true),
    Emoji('ðŸ¤·â€â™‚ï¸',
        'doubt | dunno | guess | idk | ignorance | indifference | knows | maybe | person | shrug | shrugging | whatever | who male | man | sign ',
        hasSkinTone: true),
    Emoji('ðŸ¤·â€â™€ï¸',
        'doubt | dunno | guess | idk | ignorance | indifference | knows | maybe | person | shrug | shrugging | whatever | who female | sign | woman ',
        hasSkinTone: true),
    Emoji('ðŸ‘¨â€âš•ï¸',
        'adult | bro | man aesculapius | medical | medicine | staff | symbol ',
        hasSkinTone: true),
    Emoji('ðŸ‘©â€âš•ï¸',
        'adult | lady | woman aesculapius | medical | medicine | staff | symbol ',
        hasSkinTone: true),
    Emoji('ðŸ‘¨â€ðŸŽ“', 'graduate | man | student', hasSkinTone: true),
    Emoji('ðŸ‘©â€ðŸŽ“', 'graduate | student | woman', hasSkinTone: true),
    Emoji('ðŸ‘¨â€ðŸ«', 'instructor | lecturer | man | professor | teacher',
        hasSkinTone: true),
    Emoji('ðŸ‘©â€ðŸ«', 'instructor | lecturer | professor | teacher | woman',
        hasSkinTone: true),
    Emoji('ðŸ‘¨â€âš–ï¸',
        'adult | bro | man balance | justice | Libra | scale | scales | tool | weight | zodiac ',
        hasSkinTone: true),
    Emoji('ðŸ‘©â€âš–ï¸',
        'adult | lady | woman balance | justice | Libra | scale | scales | tool | weight | zodiac ',
        hasSkinTone: true),
    Emoji('ðŸ‘¨â€ðŸŒ¾', 'farmer | gardener | man | rancher', hasSkinTone: true),
    Emoji('ðŸ‘©â€ðŸŒ¾', 'farmer | gardener | rancher | woman', hasSkinTone: true),
    Emoji('ðŸ‘¨â€ðŸ³', 'chef | cook | man', hasSkinTone: true),
    Emoji('ðŸ‘©â€ðŸ³', 'chef | cook | woman', hasSkinTone: true),
    Emoji('ðŸ‘¨â€ðŸ”§', 'electrician | man | mechanic | plumber | tradesperson',
        hasSkinTone: true),
    Emoji('ðŸ‘©â€ðŸ”§', 'electrician | mechanic | plumber | tradesperson | woman',
        hasSkinTone: true),
    Emoji('ðŸ‘¨â€ðŸ­', 'assembly | factory | industrial | man | worker',
        hasSkinTone: true),
    Emoji('ðŸ‘©â€ðŸ­', 'assembly | factory | industrial | woman | worker',
        hasSkinTone: true),
    Emoji('ðŸ‘¨â€ðŸ’¼',
        'architect | business | man | manager | office | white-collar | worker',
        hasSkinTone: true),
    Emoji('ðŸ‘©â€ðŸ’¼',
        'architect | business | manager | office | white-collar | woman | worker',
        hasSkinTone: true),
    Emoji('ðŸ‘¨â€ðŸ”¬',
        'biologist | chemist | engineer | man | mathematician | physicist | scientist',
        hasSkinTone: true),
    Emoji('ðŸ‘©â€ðŸ”¬',
        'biologist | chemist | engineer | mathematician | physicist | scientist | woman',
        hasSkinTone: true),
    Emoji('ðŸ‘¨â€ðŸ’»',
        'coder | computer | developer | inventor | man | software | technologist',
        hasSkinTone: true),
    Emoji('ðŸ‘©â€ðŸ’»',
        'coder | computer | developer | inventor | software | technologist | woman',
        hasSkinTone: true),
    Emoji(
        'ðŸ‘¨â€ðŸŽ¤', 'actor | entertainer | man | rock | rockstar | singer | star',
        hasSkinTone: true),
    Emoji('ðŸ‘©â€ðŸŽ¤',
        'actor | entertainer | rock | rockstar | singer | star | woman',
        hasSkinTone: true),
    Emoji('ðŸ‘¨â€ðŸŽ¨', 'artist | man | palette', hasSkinTone: true),
    Emoji('ðŸ‘©â€ðŸŽ¨', 'artist | palette | woman', hasSkinTone: true),
    Emoji('ðŸ‘¨â€âœˆï¸',
        'adult | bro | man aeroplane | airplane | fly | flying | jet | plane | travel ',
        hasSkinTone: true),
    Emoji('ðŸ‘©â€âœˆï¸',
        'adult | lady | woman aeroplane | airplane | fly | flying | jet | plane | travel ',
        hasSkinTone: true),
    Emoji('ðŸ‘¨â€ðŸš€', 'astronaut | man | rocket | space', hasSkinTone: true),
    Emoji('ðŸ‘©â€ðŸš€', 'astronaut | rocket | space | woman', hasSkinTone: true),
    Emoji('ðŸ‘¨â€ðŸš’', 'fire | firefighter | firetruck | man', hasSkinTone: true),
    Emoji('ðŸ‘©â€ðŸš’', 'fire | firefighter | firetruck | woman', hasSkinTone: true),
    Emoji('ðŸ‘®â€â™‚ï¸',
        'apprehend | arrest | citation | cop | law | officer | over | police | pulled | undercover male | man | sign ',
        hasSkinTone: true),
    Emoji('ðŸ‘®â€â™€ï¸',
        'apprehend | arrest | citation | cop | law | officer | over | police | pulled | undercover female | sign | woman ',
        hasSkinTone: true),
    Emoji('ðŸ•µï¸â€â™‚ï¸', 'detective | sleuth | spy male | man | sign ',
        hasSkinTone: true),
    Emoji('ðŸ•µï¸â€â™€ï¸', 'detective | sleuth | spy female | sign | woman ',
        hasSkinTone: true),
    Emoji('ðŸ’‚â€â™‚ï¸',
        'buckingham | guard | helmet | london | palace male | man | sign ',
        hasSkinTone: true),
    Emoji('ðŸ’‚â€â™€ï¸',
        'buckingham | guard | helmet | london | palace female | sign | woman ',
        hasSkinTone: true),
    Emoji('ðŸ‘·â€â™‚ï¸',
        'build | construction | fix | hardhat | hat | man | person | rebuild | remodel | repair | work | worker male | man | sign ',
        hasSkinTone: true),
    Emoji('ðŸ‘·â€â™€ï¸',
        'build | construction | fix | hardhat | hat | man | person | rebuild | remodel | repair | work | worker female | sign | woman ',
        hasSkinTone: true),
    Emoji('ðŸ¤´',
        'crown | fairy | fairytale | fantasy | king | prince | royal | royalty | tale',
        hasSkinTone: true),
    Emoji('ðŸ‘¸',
        'crown | fairy | fairytale | fantasy | princess | queen | royal | royalty | tale',
        hasSkinTone: true),
    Emoji('ðŸ‘³â€â™‚ï¸', 'person | turban | wearing male | man | sign ',
        hasSkinTone: true),
    Emoji('ðŸ‘³â€â™€ï¸', 'person | turban | wearing female | sign | woman ',
        hasSkinTone: true),
    Emoji('ðŸ‘²',
        'cap | Chinese | gua | guapi | hat | mao | person | pi | skullcap',
        hasSkinTone: true),
    Emoji('ðŸ§•',
        'bandana | head | headscarf | hijab | kerchief | mantilla | tichel | woman',
        hasSkinTone: true),
    Emoji('ðŸ¤µ', 'formal | person | tuxedo | wedding', hasSkinTone: true),
    Emoji('ðŸ‘°', 'person | veil | wedding', hasSkinTone: true),
    Emoji('ðŸ¤°', 'pregnant | woman', hasSkinTone: true),
    Emoji('ðŸ¤±',
        'baby | breast | breast-feeding | feeding | mom | mother | nursing | woman',
        hasSkinTone: true),
    Emoji('ðŸ‘¼',
        'angel | baby | church | face | fairy | fairytale | fantasy | tale',
        hasSkinTone: true),
    Emoji('ðŸŽ…',
        'celebration | Christmas | claus | fairy | fantasy | father | holiday | merry | santa | tale | xmas',
        hasSkinTone: true),
    Emoji('ðŸ¤¶',
        'celebration | Christmas | claus | fairy | fantasy | holiday | merry | mother | Mrs | santa | tale | xmas',
        hasSkinTone: true),
    Emoji('ðŸ¦¸â€â™‚ï¸', 'good | hero | superhero | superpower male | man | sign ',
        hasSkinTone: true),
    Emoji(
        'ðŸ¦¸â€â™€ï¸', 'good | hero | superhero | superpower female | sign | woman ',
        hasSkinTone: true),
    Emoji('ðŸ¦¹â€â™‚ï¸',
        'bad | criminal | evil | superpower | supervillain | villain male | man | sign ',
        hasSkinTone: true),
    Emoji('ðŸ¦¹â€â™€ï¸',
        'bad | criminal | evil | superpower | supervillain | villain female | sign | woman ',
        hasSkinTone: true),
    Emoji('ðŸ§™â€â™‚ï¸',
        'fantasy | mage | magic | play | sorcerer | sorceress | sorcery | spell | summon | witch | wizard male | man | sign ',
        hasSkinTone: true),
    Emoji('ðŸ§™â€â™€ï¸',
        'fantasy | mage | magic | play | sorcerer | sorceress | sorcery | spell | summon | witch | wizard female | sign | woman ',
        hasSkinTone: true),
    Emoji('ðŸ§šâ€â™‚ï¸',
        'fairy | fairytale | fantasy | myth | person | pixie | tale | wings male | man | sign ',
        hasSkinTone: true),
    Emoji('ðŸ§šâ€â™€ï¸',
        'fairy | fairytale | fantasy | myth | person | pixie | tale | wings female | sign | woman ',
        hasSkinTone: true),
    Emoji('ðŸ§›â€â™‚ï¸',
        'blood | Dracula | fangs | halloween | scary | supernatural | teeth | undead | vampire male | man | sign ',
        hasSkinTone: true),
    Emoji('ðŸ§›â€â™€ï¸',
        'blood | Dracula | fangs | halloween | scary | supernatural | teeth | undead | vampire female | sign | woman ',
        hasSkinTone: true),
    Emoji('ðŸ§œâ€â™‚ï¸',
        'creature | fairytale | folklore | merperson | ocean | sea | siren | trident male | man | sign ',
        hasSkinTone: true),
    Emoji('ðŸ§œâ€â™€ï¸',
        'creature | fairytale | folklore | merperson | ocean | sea | siren | trident female | sign | woman ',
        hasSkinTone: true),
    Emoji('ðŸ§â€â™‚ï¸',
        'elf | elves | enchantment | fantasy | folklore | magic | magical | myth male | man | sign ',
        hasSkinTone: true),
    Emoji('ðŸ§â€â™€ï¸',
        'elf | elves | enchantment | fantasy | folklore | magic | magical | myth female | sign | woman ',
        hasSkinTone: true),
    Emoji(
      'ðŸ§žâ€â™‚ï¸',
      'djinn | fantasy | genie | jinn | lamp | myth | rub | wishes male | man | sign ',
    ),
    Emoji(
      'ðŸ§žâ€â™€ï¸',
      'djinn | fantasy | genie | jinn | lamp | myth | rub | wishes female | sign | woman ',
    ),
    Emoji(
      'ðŸ§Ÿâ€â™‚ï¸',
      'apocalypse | dead | halloween | horror | scary | undead | walking | zombie male | man | sign ',
    ),
    Emoji(
      'ðŸ§Ÿâ€â™€ï¸',
      'apocalypse | dead | halloween | horror | scary | undead | walking | zombie female | sign | woman ',
    ),
    Emoji('ðŸ’†â€â™‚ï¸',
        'face | getting | headache | massage | person | relax | relaxing | salon | soothe | spa | tension | therapy | treatment male | man | sign ',
        hasSkinTone: true),
    Emoji('ðŸ’†â€â™€ï¸',
        'face | getting | headache | massage | person | relax | relaxing | salon | soothe | spa | tension | therapy | treatment female | sign | woman ',
        hasSkinTone: true),
    Emoji('ðŸ’‡â€â™‚ï¸',
        'barber | beauty | chop | cosmetology | cut | groom | hair | haircut | parlor | person | shears | style male | man | sign ',
        hasSkinTone: true),
    Emoji('ðŸ’‡â€â™€ï¸',
        'barber | beauty | chop | cosmetology | cut | groom | hair | haircut | parlor | person | shears | style female | sign | woman ',
        hasSkinTone: true),
    Emoji('ðŸš¶â€â™‚ï¸',
        'amble | gait | hike | man | pace | pedestrian | person | stride | stroll | walk | walking male | man | sign ',
        hasSkinTone: true),
    Emoji('ðŸš¶â€â™€ï¸',
        'amble | gait | hike | man | pace | pedestrian | person | stride | stroll | walk | walking female | sign | woman ',
        hasSkinTone: true),
    Emoji('ðŸƒâ€â™‚ï¸',
        'fast | hurry | marathon | move | person | quick | race | racing | run | rush | speed male | man | sign ',
        hasSkinTone: true),
    Emoji('ðŸƒâ€â™€ï¸',
        'fast | hurry | marathon | move | person | quick | race | racing | run | rush | speed female | sign | woman ',
        hasSkinTone: true),
    Emoji('ðŸ•º',
        'dance | dancer | dancing | elegant | festive | flair | flamenco | groove | letâ€™s | man | salsa | tango',
        hasSkinTone: true),
    Emoji('ðŸ’ƒ',
        'dance | dancer | dancing | elegant | festive | flair | flamenco | groove | letâ€™s | salsa | tango | woman',
        hasSkinTone: true),
    Emoji('ðŸ•´ï¸', 'business | levitating | person | suit ', hasSkinTone: true),
    Emoji(
      'ðŸ‘¯â€â™‚ï¸',
      'bestie | bff | bunny | counterpart | dancer | double | ear | identical | pair | party | partying | people | soulmate | twin | twinsies male | man | sign ',
    ),
    Emoji(
      'ðŸ‘¯â€â™€ï¸',
      'bestie | bff | bunny | counterpart | dancer | double | ear | identical | pair | party | partying | people | soulmate | twin | twinsies female | sign | woman ',
    ),
    Emoji('ðŸ§–â€â™‚ï¸',
        'day | luxurious | pamper | person | relax | room | sauna | spa | steam | steambath | unwind male | man | sign ',
        hasSkinTone: true),
    Emoji('ðŸ§–â€â™€ï¸',
        'day | luxurious | pamper | person | relax | room | sauna | spa | steam | steambath | unwind female | sign | woman ',
        hasSkinTone: true),
    Emoji('ðŸ§˜',
        'cross | legged | legs | lotus | meditation | peace | person | position | relax | serenity | yoga | yogi | zen',
        hasSkinTone: true),
    Emoji('ðŸ‘­',
        'bae | bestie | bff | couple | dating | flirt | friends | girls | hand | hold | sisters | twins | women',
        hasSkinTone: true),
    Emoji('ðŸ‘«',
        'bae | bestie | bff | couple | dating | flirt | friends | hand | hold | man | twins | woman',
        hasSkinTone: true),
    Emoji('ðŸ‘¬',
        'bae | bestie | bff | boys | brothers | couple | dating | flirt | friends | hand | hold | men | twins',
        hasSkinTone: true),
    Emoji(
      'ðŸ’',
      'anniversary | babe | bae | couple | date | dating | heart | kiss | love | mwah | person | romance | together | xoxo',
    ),
    Emoji(
      'ðŸ‘¨â€â¤ï¸â€ðŸ’‹â€ðŸ‘¨',
      'adult | bro | man emotion | heart | love | red dating | emotion | heart | kiss | kissing | lips | mark | romance | sexy adult | bro | man ',
    ),
    Emoji(
      'ðŸ‘©â€â¤ï¸â€ðŸ’‹â€ðŸ‘©',
      'adult | lady | woman emotion | heart | love | red dating | emotion | heart | kiss | kissing | lips | mark | romance | sexy adult | lady | woman ',
    ),
    Emoji(
      'ðŸ’‘',
      'anniversary | babe | bae | couple | dating | heart | kiss | love | person | relationship | romance | together | you',
    ),
    Emoji(
      'ðŸ‘¨â€â¤ï¸â€ðŸ‘¨',
      'adult | bro | man emotion | heart | love | red adult | bro | man ',
    ),
    Emoji(
      'ðŸ‘©â€â¤ï¸â€ðŸ‘©',
      'adult | lady | woman emotion | heart | love | red adult | lady | woman ',
    ),
    Emoji(
      'ðŸ‘ª',
      'child | family',
    ),
    Emoji(
      'ðŸ‘¨â€ðŸ‘©â€ðŸ‘¦',
      'adult | bro | man adult | lady | woman boy | bright-eyed | child | grandson | kid | son | young | younger ',
    ),
    Emoji(
      'ðŸ‘¨â€ðŸ‘©â€ðŸ‘§',
      'adult | bro | man adult | lady | woman bright-eyed | child | daughter | girl | granddaughter | kid | Virgo | young | younger | zodiac ',
    ),
    Emoji(
      'ðŸ‘¨â€ðŸ‘©â€ðŸ‘§â€ðŸ‘¦',
      'adult | bro | man adult | lady | woman bright-eyed | child | daughter | girl | granddaughter | kid | Virgo | young | younger | zodiac boy | bright-eyed | child | grandson | kid | son | young | younger ',
    ),
    Emoji(
      'ðŸ‘¨â€ðŸ‘©â€ðŸ‘¦â€ðŸ‘¦',
      'adult | bro | man adult | lady | woman boy | bright-eyed | child | grandson | kid | son | young | younger boy | bright-eyed | child | grandson | kid | son | young | younger ',
    ),
    Emoji(
      'ðŸ‘¨â€ðŸ‘©â€ðŸ‘§â€ðŸ‘§',
      'adult | bro | man adult | lady | woman bright-eyed | child | daughter | girl | granddaughter | kid | Virgo | young | younger | zodiac bright-eyed | child | daughter | girl | granddaughter | kid | Virgo | young | younger | zodiac ',
    ),
    Emoji(
      'ðŸ‘¨â€ðŸ‘¨â€ðŸ‘¦',
      'adult | bro | man adult | bro | man boy | bright-eyed | child | grandson | kid | son | young | younger ',
    ),
    Emoji(
      'ðŸ‘¨â€ðŸ‘¨â€ðŸ‘§',
      'adult | bro | man adult | bro | man bright-eyed | child | daughter | girl | granddaughter | kid | Virgo | young | younger | zodiac ',
    ),
    Emoji(
      'ðŸ‘¨â€ðŸ‘¨â€ðŸ‘§â€ðŸ‘¦',
      'adult | bro | man adult | bro | man bright-eyed | child | daughter | girl | granddaughter | kid | Virgo | young | younger | zodiac boy | bright-eyed | child | grandson | kid | son | young | younger ',
    ),
    Emoji(
      'ðŸ‘¨â€ðŸ‘¨â€ðŸ‘¦â€ðŸ‘¦',
      'adult | bro | man adult | bro | man boy | bright-eyed | child | grandson | kid | son | young | younger boy | bright-eyed | child | grandson | kid | son | young | younger ',
    ),
    Emoji(
      'ðŸ‘¨â€ðŸ‘¨â€ðŸ‘§â€ðŸ‘§',
      'adult | bro | man adult | bro | man bright-eyed | child | daughter | girl | granddaughter | kid | Virgo | young | younger | zodiac bright-eyed | child | daughter | girl | granddaughter | kid | Virgo | young | younger | zodiac ',
    ),
    Emoji(
      'ðŸ‘©â€ðŸ‘©â€ðŸ‘¦',
      'adult | lady | woman adult | lady | woman boy | bright-eyed | child | grandson | kid | son | young | younger ',
    ),
    Emoji(
      'ðŸ‘©â€ðŸ‘©â€ðŸ‘§',
      'adult | lady | woman adult | lady | woman bright-eyed | child | daughter | girl | granddaughter | kid | Virgo | young | younger | zodiac ',
    ),
    Emoji(
      'ðŸ‘©â€ðŸ‘©â€ðŸ‘§â€ðŸ‘¦',
      'adult | lady | woman adult | lady | woman bright-eyed | child | daughter | girl | granddaughter | kid | Virgo | young | younger | zodiac boy | bright-eyed | child | grandson | kid | son | young | younger ',
    ),
    Emoji(
      'ðŸ‘©â€ðŸ‘©â€ðŸ‘¦â€ðŸ‘¦',
      'adult | lady | woman adult | lady | woman boy | bright-eyed | child | grandson | kid | son | young | younger boy | bright-eyed | child | grandson | kid | son | young | younger ',
    ),
    Emoji(
      'ðŸ‘©â€ðŸ‘©â€ðŸ‘§â€ðŸ‘§',
      'adult | lady | woman adult | lady | woman bright-eyed | child | daughter | girl | granddaughter | kid | Virgo | young | younger | zodiac bright-eyed | child | daughter | girl | granddaughter | kid | Virgo | young | younger | zodiac ',
    ),
    Emoji(
      'ðŸ‘¨â€ðŸ‘¦',
      'adult | bro | man boy | bright-eyed | child | grandson | kid | son | young | younger ',
    ),
    Emoji(
      'ðŸ‘¨â€ðŸ‘¦â€ðŸ‘¦',
      'adult | bro | man boy | bright-eyed | child | grandson | kid | son | young | younger boy | bright-eyed | child | grandson | kid | son | young | younger ',
    ),
    Emoji(
      'ðŸ‘¨â€ðŸ‘§',
      'adult | bro | man bright-eyed | child | daughter | girl | granddaughter | kid | Virgo | young | younger | zodiac ',
    ),
    Emoji(
      'ðŸ‘¨â€ðŸ‘§â€ðŸ‘¦',
      'adult | bro | man bright-eyed | child | daughter | girl | granddaughter | kid | Virgo | young | younger | zodiac boy | bright-eyed | child | grandson | kid | son | young | younger ',
    ),
    Emoji(
      'ðŸ‘¨â€ðŸ‘§â€ðŸ‘§',
      'adult | bro | man bright-eyed | child | daughter | girl | granddaughter | kid | Virgo | young | younger | zodiac bright-eyed | child | daughter | girl | granddaughter | kid | Virgo | young | younger | zodiac ',
    ),
    Emoji(
      'ðŸ‘©â€ðŸ‘¦',
      'adult | lady | woman boy | bright-eyed | child | grandson | kid | son | young | younger ',
    ),
    Emoji(
      'ðŸ‘©â€ðŸ‘¦â€ðŸ‘¦',
      'adult | lady | woman boy | bright-eyed | child | grandson | kid | son | young | younger boy | bright-eyed | child | grandson | kid | son | young | younger ',
    ),
    Emoji(
      'ðŸ‘©â€ðŸ‘§',
      'adult | lady | woman bright-eyed | child | daughter | girl | granddaughter | kid | Virgo | young | younger | zodiac ',
    ),
    Emoji(
      'ðŸ‘©â€ðŸ‘§â€ðŸ‘¦',
      'adult | lady | woman bright-eyed | child | daughter | girl | granddaughter | kid | Virgo | young | younger | zodiac boy | bright-eyed | child | grandson | kid | son | young | younger ',
    ),
    Emoji(
      'ðŸ‘©â€ðŸ‘§â€ðŸ‘§',
      'adult | lady | woman bright-eyed | child | daughter | girl | granddaughter | kid | Virgo | young | younger | zodiac bright-eyed | child | daughter | girl | granddaughter | kid | Virgo | young | younger | zodiac ',
    ),
    Emoji(
      'ðŸ—£ï¸',
      'face | head | silhouette | speak | speaking ',
    ),
    Emoji(
      'ðŸ‘¤',
      'bust | mysterious | shadow | silhouette',
    ),
    Emoji(
      'ðŸ‘¥',
      'bff | bust | busts | everyone | friend | friends | people | silhouette',
    ),
    Emoji(
      'ðŸ«‚',
      'comfort | embrace | farewell | friendship | goodbye | hello | hug | hugging | love | people | thanks',
    ),
    Emoji(
      'ðŸ‘£',
      'barefoot | clothing | footprint | footprints | omw | print | walk',
    ),
    Emoji(
      'ðŸ§³',
      'bag | luggage | packing | roller | suitcase | travel',
    ),
    Emoji(
      'ðŸŒ‚',
      'closed | clothing | rain | umbrella',
    ),
    Emoji(
      'â˜‚ï¸',
      'clothing | rain | umbrella ',
    ),
    Emoji(
      'ðŸ§µ',
      'needle | sewing | spool | string | thread',
    ),
    Emoji(
      'ðŸ§¶',
      'ball | crochet | knit | yarn',
    ),
    Emoji(
      'ðŸ‘“',
      'clothing | eye | eyeglasses | eyewear | glasses',
    ),
    Emoji(
      'ðŸ•¶ï¸',
      'dark | eye | eyewear | glasses | sunglasses ',
    ),
    Emoji(
      'ðŸ¥½',
      'dive | eye | goggles | protection | scuba | swimming | welding',
    ),
    Emoji(
      'ðŸ¥¼',
      'clothes | coat | doctor | dr | experiment | jacket | lab | scientist | white',
    ),
    Emoji(
      'ðŸ‘”',
      'clothing | employed | necktie | serious | shirt | tie',
    ),
    Emoji(
      'ðŸ‘•',
      'blue | casual | clothes | clothing | collar | dressed | shirt | shopping | t-shirt | tshirt | weekend',
    ),
    Emoji(
      'ðŸ‘–',
      'blue | casual | clothes | clothing | denim | dressed | jeans | pants | shopping | trousers | weekend',
    ),
    Emoji(
      'ðŸ§£',
      'bundle | cold | neck | scarf | up',
    ),
    Emoji(
      'ðŸ§¤',
      'gloves | hand',
    ),
    Emoji(
      'ðŸ§¥',
      'brr | bundle | coat | cold | jacket | up',
    ),
    Emoji(
      'ðŸ§¦',
      'socks | stocking',
    ),
    Emoji(
      'ðŸ‘—',
      'clothes | clothing | dress | dressed | fancy | shopping',
    ),
    Emoji(
      'ðŸ‘˜',
      'clothing | comfortable | kimono',
    ),
    Emoji(
      'ðŸ‘™',
      'bathing | beach | bikini | clothing | pool | suit | swim',
    ),
    Emoji(
      'ðŸ‘š',
      'blouse | clothes | clothing | collar | dress | dressed | lady | shirt | shopping | woman | womanâ€™s',
    ),
    Emoji(
      'ðŸ‘›',
      'clothes | clothing | coin | dress | fancy | handbag | purse | shopping',
    ),
    Emoji(
      'ðŸ‘œ',
      'bag | clothes | clothing | dress | handbag | lady | purse | shopping',
    ),
    Emoji(
      'ðŸ‘',
      'bag | clothes | clothing | clutch | dress | handbag | pouch | purse',
    ),
    Emoji(
      'ðŸŽ’',
      'backpack | backpacking | bag | bookbag | education | rucksack | satchel | school',
    ),
    Emoji(
      'ðŸ‘ž',
      'brown | clothes | clothing | feet | foot | kick | man | manâ€™s | shoe | shoes | shopping',
    ),
    Emoji(
      'ðŸ‘Ÿ',
      'athletic | clothes | clothing | fast | kick | running | shoe | shoes | shopping | sneaker | tennis',
    ),
    Emoji(
      'ðŸ¥¾',
      'backpacking | boot | brown | camping | hiking | outdoors | shoe',
    ),
    Emoji(
      'ðŸ¥¿',
      'ballet | comfy | flat | flats | shoe | slip-on | slipper',
    ),
    Emoji(
      'ðŸ‘ ',
      'clothes | clothing | dress | fashion | heel | heels | high-heeled | shoe | shoes | shopping | stiletto | woman',
    ),
    Emoji(
      'ðŸ‘¡',
      'clothing | sandal | shoe | woman | womanâ€™s',
    ),
    Emoji(
      'ðŸ‘¢',
      'boot | clothes | clothing | dress | shoe | shoes | shopping | woman | womanâ€™s',
    ),
    Emoji(
      'ðŸ‘‘',
      'clothing | crown | family | king | medieval | queen | royal | royalty | win',
    ),
    Emoji(
      'ðŸ‘’',
      'clothes | clothing | garden | hat | hats | party | woman | womanâ€™s',
    ),
    Emoji(
      'ðŸŽ©',
      'clothes | clothing | fancy | formal | hat | magic | top | tophat',
    ),
    Emoji(
      'ðŸŽ“',
      'cap | celebration | clothing | education | graduation | hat | scholar',
    ),
    Emoji(
      'ðŸ§¢',
      'baseball | bent | billed | cap | dad | hat',
    ),
    Emoji(
      'â›‘ï¸',
      'aid | cross | face | hat | helmet | rescue | workerâ€™s ',
    ),
    Emoji(
      'ðŸ’„',
      'cosmetics | date | lipstick | makeup',
    ),
    Emoji(
      'ðŸ’',
      'diamond | engaged | engagement | married | ring | romance | shiny | sparkling | wedding',
    ),
    Emoji(
      'ðŸ’¼',
      'briefcase | office',
    ),
  ]),

// ======================================================= Category.ANIMALS
  CategoryEmoji(Category.ANIMALS, [
    Emoji(
      'ðŸ¶',
      'adorbs | animal | dog | face | pet | puppies | puppy',
    ),
    Emoji(
      'ðŸ±',
      'animal | cat | face | kitten | kitty | pet',
    ),
    Emoji(
      'ðŸ­',
      'animal | face | mouse',
    ),
    Emoji(
      'ðŸ¹',
      'animal | face | hamster | pet',
    ),
    Emoji(
      'ðŸ°',
      'animal | bunny | face | pet | rabbit',
    ),
    Emoji(
      'ðŸ¦Š',
      'animal | face | fox',
    ),
    Emoji(
      'ðŸ»',
      'animal | bear | face | grizzly | growl | honey',
    ),
    Emoji(
      'ðŸ¼',
      'animal | bamboo | face | panda',
    ),
    Emoji(
      'ðŸ¨',
      'animal | australia | bear | down | face | koala | marsupial | under',
    ),
    Emoji(
      'ðŸ¯',
      'animal | big | cat | face | predator | tiger',
    ),
    Emoji(
      'ðŸ¦',
      'alpha | animal | face | Leo | lion | mane | order | rawr | roar | safari | strong | zodiac',
    ),
    Emoji(
      'ðŸ®',
      'animal | cow | face | farm | milk | moo',
    ),
    Emoji(
      'ðŸ·',
      'animal | bacon | face | farm | pig | pork',
    ),
    Emoji(
      'ðŸ½',
      'animal | face | farm | nose | pig | smell | snout',
    ),
    Emoji(
      'ðŸ¸',
      'animal | face | frog',
    ),
    Emoji(
      'ðŸµ',
      'animal | banana | face | monkey',
    ),
    Emoji(
      'ðŸ™ˆ',
      'embarrassed | evil | face | forbidden | forgot | gesture | hide | monkey | no | omg | prohibited | scared | secret | smh | watch',
    ),
    Emoji(
      'ðŸ™‰',
      'animal | ears | evil | face | forbidden | gesture | hear | listen | monkey | no | not | prohibited | secret | shh | tmi',
    ),
    Emoji(
      'ðŸ™Š',
      'animal | evil | face | forbidden | gesture | monkey | no | not | oops | prohibited | quiet | secret | speak | stealth',
    ),
    Emoji(
      'ðŸ’',
      'animal | banana | monkey',
    ),
    Emoji(
      'ðŸ’¥',
      'bomb | boom | collide | collision | comic | explode',
    ),
    Emoji(
      'ðŸ’«',
      'comic | dizzy | shining | shooting | star | stars',
    ),
    Emoji(
      'ðŸ’¦',
      'comic | drip | droplet | droplets | drops | splashing | squirt | sweat | water | wet | work | workout',
    ),
    Emoji(
      'ðŸ’¨',
      'away | cloud | comic | dash | dashing | fart | fast | go | gone | gotta | running | smoke',
    ),
    Emoji(
      'ðŸ¦',
      'animal | gorilla',
    ),
    Emoji(
      'ðŸ•',
      'animal | animals | dog | dogs | pet',
    ),
    Emoji(
      'ðŸ©',
      'animal | dog | fluffy | poodle',
    ),
    Emoji(
      'ðŸº',
      'animal | face | wolf',
    ),
    Emoji(
      'ðŸ¦',
      'animal | curious | raccoon | sly',
    ),
    Emoji(
      'ðŸˆ',
      'animal | animals | cat | cats | kitten | pet',
    ),
    Emoji(
      'ðŸ…',
      'animal | big | cat | predator | tiger | zoo',
    ),
    Emoji(
      'ðŸ†',
      'animal | big | cat | leopard | predator | zoo',
    ),
    Emoji(
      'ðŸ´',
      'animal | dressage | equine | face | farm | horse | horses',
    ),
    Emoji(
      'ðŸŽ',
      'animal | equestrian | farm | horse | racehorse | racing',
    ),
    Emoji(
      'ðŸ¦„',
      'face | unicorn',
    ),
    Emoji(
      'ðŸ¦“',
      'animal | stripe | zebra',
    ),
    Emoji(
      'ðŸ‚',
      'animal | animals | bull | farm | ox | Taurus | zodiac',
    ),
    Emoji(
      'ðŸƒ',
      'animal | buffalo | water | zoo',
    ),
    Emoji(
      'ðŸ„',
      'animal | animals | cow | farm | milk | moo',
    ),
    Emoji(
      'ðŸ–',
      'animal | bacon | farm | pig | pork | sow',
    ),
    Emoji(
      'ðŸ—',
      'animal | boar | pig',
    ),
    Emoji(
      'ðŸ',
      'animal | Aries | horns | male | ram | sheep | zodiac | zoo',
    ),
    Emoji(
      'ðŸ‘',
      'animal | baa | ewe | farm | female | fluffy | lamb | sheep | wool',
    ),
    Emoji(
      'ðŸ',
      'animal | Capricorn | farm | goat | milk | zodiac',
    ),
    Emoji(
      'ðŸª',
      'animal | camel | desert | dromedary | hump | one',
    ),
    Emoji(
      'ðŸ«',
      'animal | bactrian | camel | desert | hump | two | two-hump',
    ),
    Emoji(
      'ðŸ¦™',
      'alpaca | animal | guanaco | llama | vicuÃ±a | wool',
    ),
    Emoji(
      'ðŸ¦’',
      'animal | giraffe | spots',
    ),
    Emoji(
      'ðŸ˜',
      'animal | elephant',
    ),
    Emoji(
      'ðŸ¦',
      'animal | rhinoceros',
    ),
    Emoji(
      'ðŸ¦›',
      'animal | hippo | hippopotamus',
    ),
    Emoji(
      'ðŸ',
      'animal | animals | mouse',
    ),
    Emoji(
      'ðŸ€',
      'animal | rat',
    ),
    Emoji(
      'ðŸ‡',
      'animal | bunny | pet | rabbit',
    ),
    Emoji(
      'ðŸ¿ï¸',
      'animal | chipmunk | squirrel ',
    ),
    Emoji(
      'ðŸ¦”',
      'animal | hedgehog | spiny',
    ),
    Emoji(
      'ðŸ¦‡',
      'animal | bat | vampire',
    ),
    Emoji(
      'ðŸ¦˜',
      'animal | joey | jump | kangaroo | marsupial',
    ),
    Emoji(
      'ðŸ¦¡',
      'animal | badger | honey | pester',
    ),
    Emoji(
      'ðŸ¾',
      'feet | paw | paws | print | prints',
    ),
    Emoji(
      'ðŸ¦ƒ',
      'bird | gobble | thanksgiving | turkey',
    ),
    Emoji(
      'ðŸ”',
      'animal | bird | chicken | ornithology',
    ),
    Emoji(
      'ðŸ“',
      'animal | bird | ornithology | rooster',
    ),
    Emoji(
      'ðŸ£',
      'animal | baby | bird | chick | egg | hatching',
    ),
    Emoji(
      'ðŸ¤',
      'animal | baby | bird | chick | ornithology',
    ),
    Emoji(
      'ðŸ¥',
      'animal | baby | bird | chick | front-facing | newborn | ornithology',
    ),
    Emoji(
      'ðŸ¦',
      'animal | bird | ornithology',
    ),
    Emoji(
      'ðŸ§',
      'animal | antarctica | bird | ornithology | penguin',
    ),
    Emoji(
      'ðŸ•Šï¸',
      'bird | dove | fly | ornithology | peace ',
    ),
    Emoji(
      'ðŸ¦…',
      'animal | bird | eagle | ornithology',
    ),
    Emoji(
      'ðŸ¦†',
      'animal | bird | duck | ornithology',
    ),
    Emoji(
      'ðŸ¦¢',
      'animal | bird | cygnet | duckling | ornithology | swan | ugly',
    ),
    Emoji(
      'ðŸ¦‰',
      'animal | bird | ornithology | owl | wise',
    ),
    Emoji(
      'ðŸ¦š',
      'animal | bird | colorful | ornithology | ostentatious | peacock | peahen | pretty | proud',
    ),
    Emoji(
      'ðŸ¦œ',
      'animal | bird | ornithology | parrot | pirate | talk',
    ),
    Emoji(
      'ðŸŠ',
      'animal | crocodile | zoo',
    ),
    Emoji(
      'ðŸ¢',
      'animal | terrapin | tortoise | turtle',
    ),
    Emoji(
      'ðŸ¦Ž',
      'animal | lizard | reptile',
    ),
    Emoji(
      'ðŸ',
      'animal | bearer | Ophiuchus | serpent | snake | zodiac',
    ),
    Emoji(
      'ðŸ²',
      'animal | dragon | face | fairy | fairytale | tale',
    ),
    Emoji(
      'ðŸ‰',
      'animal | dragon | fairy | fairytale | knights | tale',
    ),
    Emoji(
      'ðŸ¦•',
      'brachiosaurus | brontosaurus | dinosaur | diplodocus | sauropod',
    ),
    Emoji(
      'ðŸ¦–',
      'dinosaur | Rex | T | T-Rex | Tyrannosaurus',
    ),
    Emoji(
      'ðŸ§Œ',
      'fairy | fantasy | monster | tale | troll | trolling',
    ),
    Emoji(
      'ðŸ³',
      'animal | beach | face | ocean | spouting | whale',
    ),
    Emoji(
      'ðŸ‹',
      'animal | beach | ocean | whale',
    ),
    Emoji(
      'ðŸ¬',
      'animal | beach | dolphin | flipper | ocean',
    ),
    Emoji(
      'ðŸŸ',
      'animal | dinner | fish | fishes | fishing | Pisces | zodiac',
    ),
    Emoji(
      'ðŸ ',
      'animal | fish | fishes | tropical',
    ),
    Emoji(
      'ðŸ¡',
      'animal | blowfish | fish',
    ),
    Emoji(
      'ðŸ¦ˆ',
      'animal | fish | shark',
    ),
    Emoji(
      'ðŸ™',
      'animal | creature | ocean | octopus',
    ),
    Emoji(
      'ðŸª¹',
      'branch | empty | home | nest | nesting',
    ),
    Emoji(
      'ðŸªº',
      'bird | branch | egg | eggs | nest | nesting',
    ),
    Emoji(
      'ðŸš',
      'animal | beach | conch | sea | shell | spiral',
    ),
    Emoji(
      'ðŸª¸',
      'change | climate | coral | ocean | reef | sea',
    ),
    Emoji(
      'ðŸŒ',
      'animal | escargot | garden | nature | slug | snail',
    ),
    Emoji(
      'ðŸ¦‹',
      'butterfly | insect | pretty',
    ),
    Emoji(
      'ðŸ›',
      'animal | bug | garden | insect',
    ),
    Emoji(
      'ðŸœ',
      'animal | ant | garden | insect',
    ),
    Emoji(
      'ðŸ',
      'animal | bee | bumblebee | honey | honeybee | insect | nature | spring',
    ),
    Emoji(
      'ðŸž',
      'animal | beetle | garden | insect | lady | ladybird | ladybug | nature',
    ),
    Emoji(
      'ðŸ¦—',
      'animal | bug | cricket | grasshopper | insect | Orthoptera',
    ),
    Emoji(
      'ðŸ•·ï¸',
      'animal | insect | spider ',
    ),
    Emoji(
      'ðŸ•¸ï¸',
      'spider | web ',
    ),
    Emoji(
      'ðŸ¦‚',
      'Scorpio | scorpion | Scorpius | zodiac',
    ),
    Emoji(
      'ðŸ¦Ÿ',
      'bite | disease | fever | insect | malaria | mosquito | pest | virus',
    ),
    Emoji(
      'ðŸ¦ ',
      'amoeba | bacteria | microbe | science | virus',
    ),
    Emoji(
      'ðŸ’',
      'anniversary | birthday | bouquet | date | flower | love | plant | romance',
    ),
    Emoji(
      'ðŸŒ¸',
      'blossom | cherry | flower | plant | spring | springtime',
    ),
    Emoji(
      'ðŸ’®',
      'flower | white',
    ),
    Emoji(
      'ðŸµï¸',
      'plant | rosette ',
    ),
    Emoji(
      'ðŸª·',
      'beauty | Buddhism | calm | flower | Hinduism | lotus | peace | purity | serenity',
    ),
    Emoji(
      'ðŸŒ¹',
      'beauty | elegant | flower | love | plant | red | rose | valentine',
    ),
    Emoji(
      'ðŸ¥€',
      'dying | flower | wilted',
    ),
    Emoji(
      'ðŸŒº',
      'flower | hibiscus | plant',
    ),
    Emoji(
      'ðŸŒ»',
      'flower | outdoors | plant | sun | sunflower',
    ),
    Emoji(
      'ðŸŒ¼',
      'blossom | buttercup | dandelion | flower | plant',
    ),
    Emoji(
      'ðŸŒ·',
      'blossom | flower | growth | plant | tulip',
    ),
    Emoji(
      'ðŸŒ±',
      'plant | sapling | seedling | sprout | young',
    ),
    Emoji(
      'ðŸŒ²',
      'christmas | evergreen | forest | pine | tree',
    ),
    Emoji(
      'ðŸŒ³',
      'deciduous | forest | green | habitat | shedding | tree',
    ),
    Emoji(
      'ðŸŒ´',
      'beach | palm | plant | tree | tropical',
    ),
    Emoji(
      'ðŸŒµ',
      'cactus | desert | drought | nature | plant',
    ),
    Emoji(
      'ðŸŒ¾',
      'ear | grain | grains | plant | rice | sheaf',
    ),
    Emoji(
      'ðŸŒ¿',
      'herb | leaf | plant',
    ),
    Emoji(
      'â˜˜ï¸',
      'irish | plant | shamrock ',
    ),
    Emoji(
      'ðŸ€',
      '4 | clover | four | four-leaf | irish | leaf | lucky | plant',
    ),
    Emoji(
      'ðŸ',
      'falling | leaf | maple',
    ),
    Emoji(
      'ðŸ‚',
      'autumn | fall | fallen | falling | leaf',
    ),
    Emoji(
      'ðŸƒ',
      'blow | flutter | fluttering | leaf | wind',
    ),
    Emoji(
      'ðŸ„',
      'fungus | mushroom | toadstool',
    ),
    Emoji(
      'ðŸŒ°',
      'almond | chestnut | plant',
    ),
    Emoji(
      'ðŸ¦€',
      'Cancer | crab | zodiac',
    ),
    Emoji(
      'ðŸ¦ž',
      'animal | bisque | claws | lobster | seafood',
    ),
    Emoji(
      'ðŸ¦',
      'food | shellfish | shrimp | small',
    ),
    Emoji(
      'ðŸ¦‘',
      'animal | food | mollusk | squid',
    ),
    Emoji(
      'ðŸŒ',
      'Africa | earth | Europe | Europe-Africa | globe | showing | world',
    ),
    Emoji(
      'ðŸŒŽ',
      'Americas | earth | globe | showing | world',
    ),
    Emoji(
      'ðŸŒ',
      'Asia | Asia-Australia | Australia | earth | globe | showing | world',
    ),
    Emoji(
      'ðŸŒ',
      'earth | globe | internet | meridians | web | world | worldwide',
    ),
    Emoji(
      'ðŸŒ‘',
      'dark | moon | new | space',
    ),
    Emoji(
      'ðŸŒ’',
      'crescent | dreams | moon | space | waxing',
    ),
    Emoji(
      'ðŸŒ“',
      'first | moon | quarter | space',
    ),
    Emoji(
      'ðŸŒ”',
      'gibbous | moon | space | waxing',
    ),
    Emoji(
      'ðŸŒ•',
      'full | moon | space',
    ),
    Emoji(
      'ðŸŒ–',
      'gibbous | moon | space | waning',
    ),
    Emoji(
      'ðŸŒ—',
      'last | moon | quarter | space',
    ),
    Emoji(
      'ðŸŒ˜',
      'crescent | moon | space | waning',
    ),
    Emoji(
      'ðŸŒ™',
      'crescent | moon | ramadan | space',
    ),
    Emoji(
      'ðŸŒš',
      'face | moon | new | space',
    ),
    Emoji(
      'ðŸŒ›',
      'face | first | moon | quarter | space',
    ),
    Emoji(
      'ðŸŒœ',
      'dreams | face | last | moon | quarter',
    ),
    Emoji(
      'â˜€ï¸',
      'bright | rays | space | sun | sunny | weather ',
    ),
    Emoji(
      'ðŸŒ',
      'bright | face | full | moon',
    ),
    Emoji(
      'ðŸŒž',
      'beach | bright | day | face | heat | shine | sun | sunny | sunshine | weather',
    ),
    Emoji(
      'â­',
      'astronomy | medium | star | stars | white',
    ),
    Emoji(
      'ðŸŒŸ',
      'glittery | glow | glowing | night | shining | sparkle | star | win',
    ),
    Emoji(
      'ðŸŒ ',
      'falling | night | shooting | space | star',
    ),
    Emoji(
      'â˜ï¸',
      'cloud | weather ',
    ),
    Emoji(
      'â›…',
      'behind | cloud | cloudy | sun | weather',
    ),
    Emoji(
      'â›ˆï¸',
      'cloud | lightning | rain | thunder | thunderstorm ',
    ),
    Emoji(
      'ðŸŒ¤ï¸',
      'behind | cloud | sun | weather ',
    ),
    Emoji(
      'ðŸŒ¥ï¸',
      'behind | cloud | sun | weather ',
    ),
    Emoji(
      'ðŸŒ¦ï¸',
      'behind | cloud | rain | sun | weather ',
    ),
    Emoji(
      'ðŸŒ§ï¸',
      'cloud | rain | weather ',
    ),
    Emoji(
      'ðŸŒ¨ï¸',
      'cloud | cold | snow | weather ',
    ),
    Emoji(
      'ðŸŒ©ï¸',
      'cloud | lightning | weather ',
    ),
    Emoji(
      'ðŸŒªï¸',
      'cloud | tornado | weather | whirlwind ',
    ),
    Emoji(
      'ðŸŒ«ï¸',
      'cloud | fog | weather ',
    ),
    Emoji(
      'ðŸŒ¬ï¸',
      'blow | cloud | face | wind ',
    ),
    Emoji(
      'ðŸŒˆ',
      'gay | genderqueer | glbt | glbtq | lesbian | lgbt | lgbtq | lgbtqia | nature | pride | queer | rain | rainbow | trans | transgender | weather',
    ),
    Emoji(
      'â˜‚ï¸',
      'clothing | rain | umbrella ',
    ),
    Emoji(
      'â˜”',
      'clothing | drop | drops | rain | umbrella | weather',
    ),
    Emoji(
      'âš¡',
      'danger | electric | electricity | high | lightning | nature | thunder | thunderbolt | voltage | zap',
    ),
    Emoji(
      'â„ï¸',
      'cold | snow | snowflake | weather ',
    ),
    Emoji(
      'â˜ƒï¸',
      'cold | man | snow | snowman ',
    ),
    Emoji(
      'â›„',
      'cold | man | snow | snowman',
    ),
    Emoji(
      'â˜„ï¸',
      'comet | space ',
    ),
    Emoji(
      'ðŸ”¥',
      'af | burn | fire | flame | hot | lit | litaf | tool',
    ),
    Emoji(
      'ðŸ’§',
      'cold | comic | drop | droplet | nature | sad | sweat | tear | water | weather',
    ),
    Emoji(
      'ðŸ«§',
      'bubble | bubbles | burp | clean | floating | pearl | soap | underwater',
    ),
    Emoji(
      'ðŸŒŠ',
      'nature | ocean | surf | surfer | surfing | water | wave',
    ),
    Emoji(
      'ðŸŽ„',
      'celebration | Christmas | tree',
    ),
    Emoji(
      'âœ¨',
      '* | magic | sparkle | sparkles | star',
    ),
    Emoji(
      'ðŸŽ‹',
      'banner | celebration | Japanese | tanabata | tree',
    ),
    Emoji(
      'ðŸŽ',
      'bamboo | celebration | decoration | Japanese | pine | plant',
    ),
  ]),

// ======================================================= Category.FOODS
  CategoryEmoji(Category.FOODS, [
    Emoji(
      'ðŸ‡',
      'Dionysus | fruit | grape | grapes',
    ),
    Emoji(
      'ðŸˆ',
      'cantaloupe | fruit | melon',
    ),
    Emoji(
      'ðŸ‰',
      'fruit | watermelon',
    ),
    Emoji(
      'ðŸŠ',
      'c | citrus | fruit | nectarine | orange | tangerine | vitamin',
    ),
    Emoji(
      'ðŸ‹',
      'citrus | fruit | lemon | sour',
    ),
    Emoji(
      'ðŸŒ',
      'banana | fruit | potassium',
    ),
    Emoji(
      'ðŸ',
      'colada | fruit | pina | pineapple | tropical',
    ),
    Emoji(
      'ðŸ¥­',
      'food | fruit | mango | tropical',
    ),
    Emoji(
      'ðŸŽ',
      'apple | diet | food | fruit | health | red | ripe',
    ),
    Emoji(
      'ðŸ',
      'apple | fruit | green',
    ),
    Emoji(
      'ðŸ',
      'fruit | pear',
    ),
    Emoji(
      'ðŸ‘',
      'fruit | peach',
    ),
    Emoji(
      'ðŸ’',
      'berries | cherries | cherry | fruit | red',
    ),
    Emoji(
      'ðŸ“',
      'berry | fruit | strawberry',
    ),
    Emoji(
      'ðŸ¥',
      'food | fruit | kiwi',
    ),
    Emoji(
      'ðŸ…',
      'food | fruit | tomato | vegetable',
    ),
    Emoji(
      'ðŸ¥¥',
      'coconut | colada | palm | piÃ±a',
    ),
    Emoji(
      'ðŸ¥‘',
      'avocado | food | fruit',
    ),
    Emoji(
      'ðŸ†',
      'aubergine | eggplant | vegetable',
    ),
    Emoji(
      'ðŸ¥”',
      'food | potato | vegetable',
    ),
    Emoji(
      'ðŸ¥•',
      'carrot | food | vegetable',
    ),
    Emoji(
      'ðŸŒ½',
      'corn | crops | ear | farm | maize | maze',
    ),
    Emoji(
      'ðŸŒ¶ï¸',
      'hot | pepper ',
    ),
    Emoji(
      'ðŸ¥’',
      'cucumber | food | pickle | vegetable',
    ),
    Emoji(
      'ðŸ¥¬',
      'bok | burgers | cabbage | choy | green | kale | leafy | lettuce | salad',
    ),
    Emoji(
      'ðŸ¥¦',
      'broccoli | cabbage | wild',
    ),
    Emoji(
      'ðŸ„',
      'fungus | mushroom | toadstool',
    ),
    Emoji(
      'ðŸ¥œ',
      'food | nut | peanut | peanuts | vegetable',
    ),
    Emoji(
      'ðŸ«˜',
      'beans | food | kidney | legume | small',
    ),
    Emoji(
      'ðŸŒ°',
      'almond | chestnut | plant',
    ),
    Emoji(
      'ðŸž',
      'bread | carbs | food | grain | loaf | restaurant | toast | wheat',
    ),
    Emoji(
      'ðŸ¥',
      'bread | breakfast | crescent | croissant | food | french | roll',
    ),
    Emoji(
      'ðŸ¥–',
      'baguette | bread | food | french',
    ),
    Emoji(
      'ðŸ¥¨',
      'convoluted | pretzel | twisted',
    ),
    Emoji(
      'ðŸ¥¯',
      'bagel | bakery | bread | breakfast | schmear',
    ),
    Emoji(
      'ðŸ¥ž',
      'breakfast | crÃªpe | food | hotcake | pancake | pancakes',
    ),
    Emoji(
      'ðŸ§€',
      'cheese | wedge',
    ),
    Emoji(
      'ðŸ–',
      'bone | meat',
    ),
    Emoji(
      'ðŸ—',
      'bone | chicken | drumstick | hungry | leg | poultry | turkey',
    ),
    Emoji(
      'ðŸ¥©',
      'chop | cut | lambchop | meat | porkchop | red | steak',
    ),
    Emoji(
      'ðŸ¥“',
      'bacon | breakfast | food | meat',
    ),
    Emoji(
      'ðŸ”',
      'burger | eat | fast | food | hamburger | hungry',
    ),
    Emoji(
      'ðŸŸ',
      'fast | food | french | fries',
    ),
    Emoji(
      'ðŸ•',
      'cheese | food | hungry | pepperoni | pizza | slice',
    ),
    Emoji(
      'ðŸŒ­',
      'dog | frankfurter | hot | hotdog | sausage',
    ),
    Emoji(
      'ðŸ¥ª',
      'bread | sandwich',
    ),
    Emoji(
      'ðŸŒ®',
      'mexican | taco',
    ),
    Emoji(
      'ðŸŒ¯',
      'burrito | mexican | wrap',
    ),
    Emoji(
      'ðŸ¥™',
      'falafel | flatbread | food | gyro | kebab | stuffed',
    ),
    Emoji(
      'ðŸ³',
      'breakfast | cooking | easy | egg | fry | frying | over | pan | restaurant | side | sunny | up',
    ),
    Emoji(
      'ðŸ¥˜',
      'casserole | food | paella | pan | shallow',
    ),
    Emoji(
      'ðŸ²',
      'food | pot | soup | stew',
    ),
    Emoji(
      'ðŸ¥£',
      'bowl | breakfast | cereal | congee | oatmeal | porridge | spoon',
    ),
    Emoji(
      'ðŸ¥—',
      'food | green | salad',
    ),
    Emoji(
      'ðŸ¿',
      'corn | movie | pop | popcorn',
    ),
    Emoji(
      'ðŸ§‚',
      'condiment | flavor | mad | salt | salty | shaker | taste | upset',
    ),
    Emoji(
      'ðŸ¥«',
      'can | canned | food',
    ),
    Emoji(
      'ðŸ«™',
      'condiment | container | empty | jar | nothing | sauce | store',
    ),
    Emoji(
      'ðŸ±',
      'bento | box | food',
    ),
    Emoji(
      'ðŸ˜',
      'cracker | food | rice',
    ),
    Emoji(
      'ðŸ™',
      'ball | food | Japanese | rice',
    ),
    Emoji(
      'ðŸš',
      'cooked | food | rice',
    ),
    Emoji(
      'ðŸ›',
      'curry | food | rice',
    ),
    Emoji(
      'ðŸœ',
      'bowl | chopsticks | food | noodle | pho | ramen | soup | steaming',
    ),
    Emoji(
      'ðŸ',
      'food | meatballs | pasta | restaurant | spaghetti',
    ),
    Emoji(
      'ðŸ ',
      'food | potato | roasted | sweet',
    ),
    Emoji(
      'ðŸ¢',
      'food | kebab | oden | restaurant | seafood | skewer | stick',
    ),
    Emoji(
      'ðŸ£',
      'food | sushi',
    ),
    Emoji(
      'ðŸ¤',
      'fried | prawn | shrimp | tempura',
    ),
    Emoji(
      'ðŸ¥',
      'cake | fish | food | pastry | restaurant | swirl',
    ),
    Emoji(
      'ðŸ¥®',
      'autumn | cake | festival | moon | yuÃ¨bÇng',
    ),
    Emoji(
      'ðŸ¡',
      'dango | dessert | Japanese | skewer | stick | sweet',
    ),
    Emoji(
      'ðŸ¥Ÿ',
      'dumpling | empanada | gyÅza | jiaozi | pierogi | potsticker',
    ),
    Emoji(
      'ðŸ¥ ',
      'cookie | fortune | prophecy',
    ),
    Emoji(
      'ðŸ¥¡',
      'box | chopsticks | delivery | food | oyster | pail | takeout',
    ),
    Emoji(
      'ðŸ¦',
      'cream | dessert | food | ice | icecream | restaurant | serve | soft | sweet',
    ),
    Emoji(
      'ðŸ§',
      'dessert | ice | restaurant | shaved | sweet',
    ),
    Emoji(
      'ðŸ¨',
      'cream | dessert | food | ice | restaurant | sweet',
    ),
    Emoji(
      'ðŸ©',
      'breakfast | dessert | donut | doughnut | food | sweet',
    ),
    Emoji(
      'ðŸª',
      'chip | chocolate | cookie | dessert | sweet',
    ),
    Emoji(
      'ðŸŽ‚',
      'bday | birthday | cake | celebration | dessert | happy | pastry | sweet',
    ),
    Emoji(
      'ðŸ°',
      'cake | dessert | pastry | shortcake | slice | sweet',
    ),
    Emoji(
      'ðŸ§',
      'bakery | cupcake | dessert | sprinkles | sugar | sweet | treat',
    ),
    Emoji(
      'ðŸ¥§',
      'apple | filling | fruit | meat | pastry | pie | pumpkin | slice',
    ),
    Emoji(
      'ðŸ«',
      'bar | candy | chocolate | dessert | halloween | sweet | tooth',
    ),
    Emoji(
      'ðŸ¬',
      'candy | cavities | dessert | halloween | restaurant | sweet | tooth | wrapper',
    ),
    Emoji(
      'ðŸ­',
      'candy | dessert | food | lollipop | restaurant | sweet',
    ),
    Emoji(
      'ðŸ®',
      'custard | dessert | pudding | sweet',
    ),
    Emoji(
      'ðŸ¯',
      'barrel | bear | food | honey | honeypot | jar | pot | sweet',
    ),
    Emoji(
      'ðŸ¼',
      'babies | baby | birth | born | bottle | drink | infant | milk | newborn',
    ),
    Emoji(
      'ðŸ¥›',
      'drink | glass | milk',
    ),
    Emoji(
      'ðŸ«—',
      'accident | drink | empty | glass | liquid | oops | pour | pouring | spill | water',
    ),
    Emoji(
      'â˜•',
      'beverage | cafe | caffeine | chai | coffee | drink | hot | morning | steaming | tea',
    ),
    Emoji(
      'ðŸµ',
      'beverage | cup | drink | handle | oolong | tea | teacup',
    ),
    Emoji(
      'ðŸ§‰',
      'drink | mate',
    ),
    Emoji(
      'ðŸ¶',
      'bar | beverage | bottle | cup | drink | restaurant | sake',
    ),
    Emoji(
      'ðŸ¾',
      'bar | bottle | cork | drink | popping',
    ),
    Emoji(
      'ðŸ·',
      'alcohol | bar | beverage | booze | club | drink | drinking | drinks | glass | restaurant | wine',
    ),
    Emoji(
      'ðŸ¸',
      'alcohol | bar | booze | club | cocktail | drink | drinking | drinks | glass | mad | martini | men',
    ),
    Emoji(
      'ðŸ¹',
      'alcohol | bar | booze | club | cocktail | drink | drinking | drinks | drunk | mai | party | tai | tropical | tropics',
    ),
    Emoji(
      'ðŸº',
      'alcohol | ale | bar | beer | booze | drink | drinking | drinks | mug | octoberfest | oktoberfest | pint | stein | summer',
    ),
    Emoji(
      'ðŸ»',
      'alcohol | bar | beer | booze | bottoms | cheers | clink | clinking | drinking | drinks | mugs',
    ),
    Emoji(
      'ðŸ¥‚',
      'celebrate | clink | clinking | drink | glass | glasses',
    ),
    Emoji(
      'ðŸ¥ƒ',
      'glass | liquor | scotch | shot | tumbler | whiskey | whisky',
    ),
    Emoji(
      'ðŸ¥¤',
      'cup | drink | juice | malt | soda | soft | straw | water',
    ),
    Emoji(
      'ðŸ¥¢',
      'chopsticks | hashi | jeotgarak | kuaizi',
    ),
    Emoji(
      'ðŸ½ï¸',
      'cooking | dinner | eat | fork | knife | plate ',
    ),
    Emoji(
      'ðŸ´',
      'breakfast | breaky | cooking | cutlery | delicious | dinner | eat | feed | food | fork | hungry | knife | lunch | restaurant | yum | yummy',
    ),
    Emoji(
      'ðŸ¥„',
      'eat | spoon | tableware',
    ),
  ]),

// ======================================================= Category.TRAVEL
  CategoryEmoji(Category.TRAVEL, [
    Emoji(
      'ðŸ—¾',
      'Japan | map',
    ),
    Emoji(
      'ðŸ”ï¸',
      'cold | mountain | snow | snow-capped ',
    ),
    Emoji(
      'â›°ï¸',
      'mountain ',
    ),
    Emoji(
      'ðŸŒ‹',
      'eruption | mountain | nature | volcano',
    ),
    Emoji(
      'ðŸ—»',
      'fuji | mount | mountain | nature',
    ),
    Emoji(
      'ðŸ•ï¸',
      'camping ',
    ),
    Emoji(
      'ðŸ–ï¸',
      'beach | umbrella ',
    ),
    Emoji(
      'ðŸœï¸',
      'desert ',
    ),
    Emoji(
      'ðŸï¸',
      'desert | island ',
    ),
    Emoji(
      'ðŸžï¸',
      'national | park ',
    ),
    Emoji(
      'ðŸŸï¸',
      'stadium ',
    ),
    Emoji(
      'ðŸ›ï¸',
      'building | classical ',
    ),
    Emoji(
      'ðŸ—ï¸',
      'building | construction | crane ',
    ),
    Emoji(
      'ðŸ˜ï¸',
      'house | houses ',
    ),
    Emoji(
      'ðŸšï¸',
      'derelict | home | house ',
    ),
    Emoji(
      'ðŸ ',
      'building | country | heart | home | house | ranch | settle | simple | suburban | suburbia | where',
    ),
    Emoji(
      'ðŸ¡',
      'building | country | garden | heart | home | house | ranch | settle | simple | suburban | suburbia | where',
    ),
    Emoji(
      'ðŸ¢',
      'building | city | cubical | job | office',
    ),
    Emoji(
      'ðŸ£',
      'building | Japanese | office | post',
    ),
    Emoji(
      'ðŸ¤',
      'building | European | office | post',
    ),
    Emoji(
      'ðŸ¥',
      'building | doctor | hospital | medicine',
    ),
    Emoji(
      'ðŸ¦',
      'bank | building',
    ),
    Emoji(
      'ðŸ¨',
      'building | hotel',
    ),
    Emoji(
      'ðŸ©',
      'building | hotel | love',
    ),
    Emoji(
      'ðŸª',
      '24 | building | convenience | hours | store',
    ),
    Emoji(
      'ðŸ«',
      'building | school',
    ),
    Emoji(
      'ðŸ¬',
      'building | department | store',
    ),
    Emoji(
      'ðŸ­',
      'building | factory',
    ),
    Emoji(
      'ðŸ¯',
      'building | castle | Japanese',
    ),
    Emoji(
      'ðŸ°',
      'building | castle | European',
    ),
    Emoji(
      'ðŸ’’',
      'chapel | hitched | nuptials | romance | wedding',
    ),
    Emoji(
      'ðŸ—¼',
      'Tokyo | tower',
    ),
    Emoji(
      'ðŸ—½',
      'liberty | Liberty | new | ny | nyc | statue | Statue | york',
    ),
    Emoji(
      'â›ª',
      'bless | chapel | Christian | church | cross | religion',
    ),
    Emoji(
      'ðŸ•Œ',
      'islam | masjid | mosque | Muslim | religion',
    ),
    Emoji(
      'ðŸ•',
      'Jew | Jewish | judaism | religion | synagogue | temple',
    ),
    Emoji(
      'â›©ï¸',
      'religion | shinto | shrine ',
    ),
    Emoji(
      'ðŸ•‹',
      'hajj | islam | kaaba | Muslim | religion | umrah',
    ),
    Emoji(
      'â›²',
      'fountain',
    ),
    Emoji(
      'â›º',
      'camping | tent',
    ),
    Emoji(
      'ðŸŒ',
      'fog | foggy',
    ),
    Emoji(
      'ðŸŒƒ',
      'night | star | stars',
    ),
    Emoji(
      'ðŸ™ï¸',
      'city | cityscape ',
    ),
    Emoji(
      'ðŸŒ„',
      'morning | mountains | over | sun | sunrise',
    ),
    Emoji(
      'ðŸŒ…',
      'morning | nature | sun | sunrise',
    ),
    Emoji(
      'ðŸŒ†',
      'at | building | city | cityscape | dusk | evening | landscape | sun | sunset',
    ),
    Emoji(
      'ðŸŒ‡',
      'building | dusk | sun | sunset',
    ),
    Emoji(
      'ðŸŒ‰',
      'at | bridge | night',
    ),
    Emoji(
      'ðŸŽ ',
      'carousel | entertainment | horse',
    ),
    Emoji(
      'ðŸŽ¡',
      'amusement | ferris | park | theme | wheel',
    ),
    Emoji(
      'ðŸŽ¢',
      'amusement | coaster | park | roller | theme',
    ),
    Emoji(
      'ðŸš‚',
      'caboose | engine | locomotive | railway | steam | train | trains | travel',
    ),
    Emoji(
      'ðŸšƒ',
      'car | electric | railway | train | tram | travel | trolleybus',
    ),
    Emoji(
      'ðŸš„',
      'high-speed | railway | shinkansen | speed | train',
    ),
    Emoji(
      'ðŸš…',
      'bullet | high-speed | nose | railway | shinkansen | speed | train | travel',
    ),
    Emoji(
      'ðŸš†',
      'arrived | choo | railway | train',
    ),
    Emoji(
      'ðŸš‡',
      'metro | subway | travel',
    ),
    Emoji(
      'ðŸšˆ',
      'arrived | light | monorail | rail | railway',
    ),
    Emoji(
      'ðŸš‰',
      'railway | station | train',
    ),
    Emoji(
      'ðŸšŠ',
      'tram | trolleybus',
    ),
    Emoji(
      'ðŸš',
      'monorail | vehicle',
    ),
    Emoji(
      'ðŸšž',
      'car | mountain | railway | trip',
    ),
    Emoji(
      'ðŸš‹',
      'bus | car | tram | trolley | trolleybus',
    ),
    Emoji(
      'ðŸšŒ',
      'bus | school | vehicle',
    ),
    Emoji(
      'ðŸš',
      'bus | cars | oncoming',
    ),
    Emoji(
      'ðŸšŽ',
      'bus | tram | trolley | trolleybus',
    ),
    Emoji(
      'ðŸš',
      'bus | drive | minibus | van | vehicle',
    ),
    Emoji(
      'ðŸš‘',
      'ambulance | emergency | vehicle',
    ),
    Emoji(
      'ðŸš’',
      'engine | fire | truck',
    ),
    Emoji(
      'ðŸš“',
      '5â€“0 | car | cops | patrol | police',
    ),
    Emoji(
      'ðŸš”',
      'car | oncoming | police',
    ),
    Emoji(
      'ðŸš•',
      'cab | cabbie | car | drive | taxi | vehicle | yellow',
    ),
    Emoji(
      'ðŸš–',
      'cab | cabbie | cars | drove | hail | oncoming | taxi | yellow',
    ),
    Emoji(
      'ðŸš—',
      'automobile | car | driving | vehicle',
    ),
    Emoji(
      'ðŸš˜',
      'automobile | car | cars | drove | oncoming | vehicle',
    ),
    Emoji(
      'ðŸšš',
      'car | delivery | drive | truck | vehicle',
    ),
    Emoji(
      'ðŸš›',
      'articulated | car | drive | lorry | move | semi | truck | vehicle',
    ),
    Emoji(
      'ðŸšœ',
      'tractor | vehicle',
    ),
    Emoji(
      'ðŸŽï¸',
      'car | racing | zoom ',
    ),
    Emoji(
      'ðŸï¸',
      'motorcycle | racing ',
    ),
    Emoji(
      'ðŸ›µ',
      'motor | scooter',
    ),
    Emoji(
      'ðŸš²',
      'bicycle | bike | class | cycle | cycling | cyclist | gang | ride | spin | spinning',
    ),
    Emoji(
      'ðŸ›´',
      'kick | scooter',
    ),
    Emoji(
      'ðŸš',
      'bus | busstop | stop',
    ),
    Emoji(
      'ðŸ›¤ï¸',
      'railway | track | train ',
    ),
    Emoji(
      'â›½',
      'diesel | fuel | fuelpump | gas | gasoline | pump | station',
    ),
    Emoji(
      'ðŸ›ž',
      'car | circle | tire | turn | vehicle | wheel',
    ),
    Emoji(
      'ðŸš¨',
      'alarm | alert | beacon | car | emergency | light | police | revolving | siren',
    ),
    Emoji(
      'ðŸš¥',
      'horizontal | intersection | light | signal | stop | stoplight | traffic',
    ),
    Emoji(
      'ðŸš¦',
      'drove | intersection | light | signal | stop | stoplight | traffic | vertical',
    ),
    Emoji(
      'ðŸš§',
      'barrier | construction',
    ),
    Emoji(
      'âš“',
      'anchor | ship | tool',
    ),
    Emoji(
      'â›µ',
      'boat | resort | sailboat | sailing | sea | yacht',
    ),
    Emoji(
      'ðŸš¤',
      'billionaire | boat | lake | luxury | millionaire | speedboat | summer | travel',
    ),
    Emoji(
      'ðŸ›³ï¸',
      'passenger | ship ',
    ),
    Emoji(
      'â›´ï¸',
      'boat | ferry | passenger ',
    ),
    Emoji(
      'ðŸ›¥ï¸',
      'boat | motor | motorboat ',
    ),
    Emoji(
      'ðŸš¢',
      'boat | passenger | ship | travel',
    ),
    Emoji(
      'ðŸ›Ÿ',
      'buoy | float | life | lifesaver | preserver | rescue | ring | safety | save | saver | swim',
    ),
    Emoji(
      'âœˆï¸',
      'aeroplane | airplane | fly | flying | jet | plane | travel ',
    ),
    Emoji(
      'ðŸ›©ï¸',
      'aeroplane | airplane | plane | small ',
    ),
    Emoji(
      'ðŸ›«',
      'aeroplane | airplane | check-in | departure | departures | plane',
    ),
    Emoji(
      'ðŸ›¬',
      'aeroplane | airplane | arrival | arrivals | arriving | landing | plane',
    ),
    Emoji(
      'ðŸ’º',
      'chair | seat',
    ),
    Emoji(
      'ðŸš',
      'copter | helicopter | roflcopter | travel | vehicle',
    ),
    Emoji(
      'ðŸšŸ',
      'railway | suspension',
    ),
    Emoji(
      'ðŸš ',
      'cable | cableway | gondola | lift | mountain | ski',
    ),
    Emoji(
      'ðŸš¡',
      'aerial | cable | car | gondola | ropeway | tramway',
    ),
    Emoji(
      'ðŸ›°ï¸',
      'satellite | space ',
    ),
    Emoji(
      'ðŸš€',
      'launch | rocket | rockets | space | travel',
    ),
    Emoji(
      'ðŸ›¸',
      'aliens | extra | flying | saucer | terrestrial | UFO',
    ),
    Emoji(
      'ðŸŒ ',
      'falling | night | shooting | space | star',
    ),
    Emoji(
      'ðŸŒŒ',
      'milky | space | way',
    ),
    Emoji(
      'â›±ï¸',
      'ground | rain | sun | umbrella ',
    ),
    Emoji(
      'ðŸŽ†',
      'boom | celebration | entertainment | fireworks | yolo',
    ),
    Emoji(
      'ðŸŽ‡',
      'boom | celebration | fireworks | sparkle | sparkler',
    ),
    Emoji(
      'ðŸŽ‘',
      'celebration | ceremony | moon | viewing',
    ),
    Emoji(
      'ðŸ—¿',
      'face | moai | moyai | statue | stoneface | travel',
    ),
    Emoji(
      'ðŸ›‚',
      'control | passport',
    ),
    Emoji(
      'ðŸ›ƒ',
      'customs | packing',
    ),
    Emoji(
      'ðŸ›„',
      'arrived | baggage | bags | case | checked | claim | journey | packing | plane | ready | travel | trip',
    ),
    Emoji(
      'ðŸ›…',
      'baggage | case | left | locker | luggage',
    ),
  ]),

// ======================================================= Category.ACTIVITIES
  CategoryEmoji(Category.ACTIVITIES, [
    Emoji('ðŸ§—â€â™‚ï¸',
        'climb | climber | climbing | mountain | person | rock | scale | up male | man | sign ',
        hasSkinTone: true),
    Emoji('ðŸ§—â€â™€ï¸',
        'climb | climber | climbing | mountain | person | rock | scale | up female | sign | woman ',
        hasSkinTone: true),
    Emoji('ðŸ‡', 'horse | jockey | racehorse | racing | riding | sport',
        hasSkinTone: true),
    Emoji(
      'â›·ï¸',
      'ski | skier | snow ',
    ),
    Emoji(
      'ðŸ‚',
      'ski | snow | snowboard | snowboarder | sport',
    ),
    Emoji('ðŸŒï¸â€â™‚ï¸',
        'ball | birdie | caddy | driving | golf | golfing | green | person | pga | putt | range | tee male | man | sign ',
        hasSkinTone: true),
    Emoji('ðŸŒï¸â€â™€ï¸',
        'ball | birdie | caddy | driving | golf | golfing | green | person | pga | putt | range | tee female | sign | woman ',
        hasSkinTone: true),
    Emoji('ðŸ„â€â™‚ï¸',
        'beach | ocean | person | sport | surf | surfer | surfing | swell | waves male | man | sign ',
        hasSkinTone: true),
    Emoji('ðŸ„â€â™€ï¸',
        'beach | ocean | person | sport | surf | surfer | surfing | swell | waves female | sign | woman ',
        hasSkinTone: true),
    Emoji('ðŸš£â€â™‚ï¸',
        'boat | canoe | cruise | fishing | lake | oar | paddle | person | raft | river | row | rowboat | rowing male | man | sign ',
        hasSkinTone: true),
    Emoji('ðŸš£â€â™€ï¸',
        'boat | canoe | cruise | fishing | lake | oar | paddle | person | raft | river | row | rowboat | rowing female | sign | woman ',
        hasSkinTone: true),
    Emoji('ðŸŠâ€â™‚ï¸',
        'freestyle | person | sport | swim | swimmer | swimming | triathlon male | man | sign ',
        hasSkinTone: true),
    Emoji('ðŸŠâ€â™€ï¸',
        'freestyle | person | sport | swim | swimmer | swimming | triathlon female | sign | woman ',
        hasSkinTone: true),
    Emoji('â›¹ï¸â€â™‚ï¸',
        'athletic | ball | basketball | bouncing | championship | dribble | net | person | player | throw male | man | sign ',
        hasSkinTone: true),
    Emoji('â›¹ï¸â€â™€ï¸',
        'athletic | ball | basketball | bouncing | championship | dribble | net | person | player | throw female | sign | woman ',
        hasSkinTone: true),
    Emoji('ðŸ‹ï¸â€â™‚ï¸',
        'barbell | bodybuilder | deadlift | lifter | lifting | person | powerlifting | weight | weightlifter | weights | workout male | man | sign ',
        hasSkinTone: true),
    Emoji('ðŸ‹ï¸â€â™€ï¸',
        'barbell | bodybuilder | deadlift | lifter | lifting | person | powerlifting | weight | weightlifter | weights | workout female | sign | woman ',
        hasSkinTone: true),
    Emoji('ðŸš´â€â™‚ï¸',
        'bicycle | bicyclist | bike | biking | cycle | cyclist | person | riding | sport male | man | sign ',
        hasSkinTone: true),
    Emoji('ðŸš´â€â™€ï¸',
        'bicycle | bicyclist | bike | biking | cycle | cyclist | person | riding | sport female | sign | woman ',
        hasSkinTone: true),
    Emoji('ðŸšµâ€â™‚ï¸',
        'bicycle | bicyclist | bike | biking | cycle | cyclist | mountain | person | riding | sport male | man | sign ',
        hasSkinTone: true),
    Emoji('ðŸšµâ€â™€ï¸',
        'bicycle | bicyclist | bike | biking | cycle | cyclist | mountain | person | riding | sport female | sign | woman ',
        hasSkinTone: true),
    Emoji('ðŸ¤¸â€â™‚ï¸',
        'active | cartwheel | cartwheeling | excited | flip | gymnastics | happy | person | somersault male | man | sign ',
        hasSkinTone: true),
    Emoji('ðŸ¤¸â€â™€ï¸',
        'active | cartwheel | cartwheeling | excited | flip | gymnastics | happy | person | somersault female | sign | woman ',
        hasSkinTone: true),
    Emoji('ðŸ¤¼â€â™‚ï¸',
        'combat | duel | grapple | people | ring | tournament | wrestle | wrestling male | man | sign ',
        hasSkinTone: true),
    Emoji('ðŸ¤¼â€â™€ï¸',
        'combat | duel | grapple | people | ring | tournament | wrestle | wrestling female | sign | woman ',
        hasSkinTone: true),
    Emoji('ðŸ¤½â€â™‚ï¸',
        'person | playing | polo | sport | swimming | water | waterpolo male | man | sign ',
        hasSkinTone: true),
    Emoji('ðŸ¤½â€â™€ï¸',
        'person | playing | polo | sport | swimming | water | waterpolo female | sign | woman ',
        hasSkinTone: true),
    Emoji('ðŸ¤¾â€â™‚ï¸',
        'athletics | ball | catch | chuck | handball | hurl | lob | person | pitch | playing | sport | throw | toss male | man | sign ',
        hasSkinTone: true),
    Emoji('ðŸ¤¾â€â™€ï¸',
        'athletics | ball | catch | chuck | handball | hurl | lob | person | pitch | playing | sport | throw | toss female | sign | woman ',
        hasSkinTone: true),
    Emoji('ðŸ¤¹â€â™‚ï¸',
        'act | balance | balancing | handle | juggle | juggling | manage | multitask | person | skill male | man | sign ',
        hasSkinTone: true),
    Emoji('ðŸ¤¹â€â™€ï¸',
        'act | balance | balancing | handle | juggle | juggling | manage | multitask | person | skill female | sign | woman ',
        hasSkinTone: true),
    Emoji('ðŸ§˜â€â™‚ï¸',
        'cross | legged | legs | lotus | meditation | peace | person | position | relax | serenity | yoga | yogi | zen male | man | sign ',
        hasSkinTone: true),
    Emoji('ðŸ§˜â€â™€ï¸',
        'cross | legged | legs | lotus | meditation | peace | person | position | relax | serenity | yoga | yogi | zen female | sign | woman ',
        hasSkinTone: true),
    Emoji(
      'ðŸŽª',
      'circus | tent',
    ),
    Emoji(
      'ðŸ›¹',
      'board | skate | skateboard | skater | wheels',
    ),
    Emoji(
      'ðŸŽ—ï¸',
      'celebration | reminder | ribbon ',
    ),
    Emoji(
      'ðŸŽŸï¸',
      'admission | ticket | tickets ',
    ),
    Emoji(
      'ðŸŽ«',
      'admission | stub | ticket',
    ),
    Emoji(
      'ðŸŽ–ï¸',
      'award | celebration | medal | military ',
    ),
    Emoji(
      'ðŸ†',
      'champion | champs | prize | slay | sport | trophy | victory | win | winning',
    ),
    Emoji(
      'ðŸ…',
      'award | gold | medal | sports | winner',
    ),
    Emoji(
      'ðŸ¥‡',
      '1st | first | gold | medal | place',
    ),
    Emoji(
      'ðŸ¥ˆ',
      '2nd | medal | place | second | silver',
    ),
    Emoji(
      'ðŸ¥‰',
      '3rd | bronze | medal | place | third',
    ),
    Emoji(
      'âš½',
      'ball | football | futbol | soccer | sport',
    ),
    Emoji(
      'âš¾',
      'ball | baseball | sport',
    ),
    Emoji(
      'ðŸ¥Ž',
      'ball | glove | softball | sports | underarm',
    ),
    Emoji(
      'ðŸ€',
      'ball | basketball | hoop | sport',
    ),
    Emoji(
      'ðŸ',
      'ball | game | volleyball',
    ),
    Emoji(
      'ðŸˆ',
      'american | ball | bowl | football | sport | super',
    ),
    Emoji(
      'ðŸ‰',
      'ball | football | rugby | sport',
    ),
    Emoji(
      'ðŸŽ¾',
      'ball | racquet | sport | tennis',
    ),
    Emoji(
      'ðŸ¥',
      'disc | flying | ultimate',
    ),
    Emoji(
      'ðŸŽ³',
      'ball | bowling | game | sport | strike',
    ),
    Emoji(
      'ðŸ',
      'ball | bat | cricket | game',
    ),
    Emoji(
      'ðŸ‘',
      'ball | field | game | hockey | stick',
    ),
    Emoji(
      'ðŸ’',
      'game | hockey | ice | puck | stick',
    ),
    Emoji(
      'ðŸ¥',
      'ball | goal | lacrosse | sports | stick',
    ),
    Emoji(
      'ðŸ“',
      'ball | bat | game | paddle | ping | pingpong | pong | table | tennis',
    ),
    Emoji(
      'ðŸ¸',
      'badminton | birdie | game | racquet | shuttlecock',
    ),
    Emoji(
      'ðŸªƒ',
      'boomerang | rebound | repercussion | weapon',
    ),
    Emoji(
      'ðŸ¥…',
      'goal | net',
    ),
    Emoji(
      'â›³',
      'flag | golf | hole | sport',
    ),
    Emoji(
      'ðŸª',
      'fly | kite | soar',
    ),
    Emoji(
      'ðŸ›',
      'amusement | park | play | playground | playing | slide | sliding | theme',
    ),
    Emoji(
      'ðŸ¹',
      'archer | archery | arrow | bow | Sagittarius | tool | weapon | zodiac',
    ),
    Emoji(
      'ðŸŽ£',
      'entertainment | fish | fishing | pole | sport',
    ),
    Emoji(
      'ðŸ¤¿ ',
      'diving | mask | scuba | snorkeling',
    ),
    Emoji(
      'ðŸ¥Š',
      'boxing | glove',
    ),
    Emoji(
      'ðŸ¥‹',
      'arts | judo | karate | martial | taekwondo | uniform',
    ),
    Emoji(
      'ðŸŽ½',
      'athletics | running | sash | shirt',
    ),
    Emoji(
      'ðŸ›¼',
      'blades | roller | skate | skates | sport',
    ),
    Emoji(
      'ðŸ›·',
      'luge | sled | sledge | sleigh | snow | toboggan',
    ),
    Emoji(
      'â›¸ï¸',
      'ice | skate | skating ',
    ),
    Emoji(
      'ðŸ¥Œ',
      'curling | game | rock | stone',
    ),
    Emoji(
      'ðŸŽ¿',
      'ski | skis | snow | sport',
    ),
    Emoji(
      'ðŸŽ¯',
      'bull | bullseye | dart | direct | entertainment | game | hit | target',
    ),
    Emoji(
      'ðŸŽ±',
      '8 | 8ball | ball | billiard | eight | game | pool',
    ),
    Emoji(
      'ðŸŽ®',
      'controller | entertainment | game | video',
    ),
    Emoji(
      'ðŸŽ°',
      'casino | gamble | gambling | game | machine | slot | slots',
    ),
    Emoji(
      'ðŸŽ²',
      'dice | die | entertainment | game',
    ),
    Emoji(
      'ðŸ§©',
      'clue | interlocking | jigsaw | piece | puzzle',
    ),
    Emoji(
      'â™Ÿï¸',
      'chess | dupe | expendable | pawn ',
    ),
    Emoji(
      'ðŸŽ­',
      'actor | actress | art | arts | entertainment | mask | performing | theater | theatre | thespian',
    ),
    Emoji(
      'ðŸŽ¨',
      'art | artist | artsy | arty | colorful | creative | entertainment | museum | painter | painting | palette',
    ),
    Emoji(
      'ðŸ§µ',
      'needle | sewing | spool | string | thread',
    ),
    Emoji(
      'ðŸ§¶',
      'ball | crochet | knit | yarn',
    ),
    Emoji(
      'ðŸŽ¼',
      'music | musical | note | score',
    ),
    Emoji(
      'ðŸŽ¤',
      'karaoke | mic | microphone | music | sing | sound',
    ),
    Emoji(
      'ðŸŽ§',
      'earbud | headphone | sound',
    ),
    Emoji(
      'ðŸŽ·',
      'instrument | music | sax | saxophone',
    ),
    Emoji(
      'ðŸŽ¸',
      'guitar | instrument | music | strat',
    ),
    Emoji(
      'ðŸŽ¹',
      'instrument | keyboard | music | musical | piano',
    ),
    Emoji(
      'ðŸŽº',
      'instrument | music | trumpet',
    ),
    Emoji(
      'ðŸŽ»',
      'instrument | music | violin',
    ),
    Emoji(
      'ðŸ¥',
      'drum | drumsticks | music',
    ),
    Emoji(
      'ðŸŽ¬',
      'action | board | clapper | movie',
    ),
  ]),

// ======================================================= Category.OBJECTS
  CategoryEmoji(Category.OBJECTS, [
    Emoji(
      'ðŸ’Œ',
      'heart | letter | love | mail | romance | valentine',
    ),
    Emoji(
      'ðŸ•³ï¸',
      'hole ',
    ),
    Emoji(
      'ðŸ’£',
      'bomb | boom | comic | dangerous | explosion | hot',
    ),
    Emoji(
      'ðŸ›€',
      'bath | bathtub | person | taking | tub',
    ),
    Emoji(
      'ðŸ›Œ',
      'bed | bedtime | good | goodnight | hotel | nap | night | person | sleep | tired | zzz',
    ),
    Emoji(
      'ðŸº',
      'amphora | Aquarius | cooking | drink | jug | tool | weapon | zodiac',
    ),
    Emoji(
      'ðŸ—ºï¸',
      'map | world ',
    ),
    Emoji(
      'ðŸ§­',
      'compass | direction | magnetic | navigation | orienteering',
    ),
    Emoji(
      'ðŸ§±',
      'brick | bricks | clay | mortar | wall',
    ),
    Emoji(
      'ðŸ’ˆ',
      'barber | cut | fresh | haircut | pole | shave',
    ),
    Emoji(
      'ðŸ›¢ï¸',
      'drum | oil ',
    ),
    Emoji(
      'ðŸ›Žï¸',
      'bell | bellhop | hotel ',
    ),
    Emoji(
      'ðŸ§³',
      'bag | luggage | packing | roller | suitcase | travel',
    ),
    Emoji(
      'âŒ›',
      'done | hourglass | sand | time | timer',
    ),
    Emoji(
      'â³',
      'done | flowing | hourglass | hours | not | sand | timer | waiting | yolo',
    ),
    Emoji(
      'âŒš',
      'clock | time | watch',
    ),
    Emoji(
      'â°',
      'alarm | clock | hours | hrs | late | time | waiting',
    ),
    Emoji(
      'â±ï¸',
      'clock | stopwatch | time ',
    ),
    Emoji(
      'â²ï¸',
      'clock | timer ',
    ),
    Emoji(
      'ðŸ•°ï¸',
      'clock | mantelpiece | time ',
    ),
    Emoji(
      'ðŸŒ¡ï¸',
      'thermometer | weather ',
    ),
    Emoji(
      'â›±ï¸',
      'ground | rain | sun | umbrella ',
    ),
    Emoji(
      'ðŸ§¨',
      'dynamite | explosive | fire | firecracker | fireworks | light | pop | popping | spark',
    ),
    Emoji(
      'ðŸŽˆ',
      'balloon | birthday | celebrate | celebration',
    ),
    Emoji(
      'ðŸŽ‰',
      'awesome | birthday | celebrate | celebration | excited | hooray | party | popper | tada | woohoo',
    ),
    Emoji(
      'ðŸŽŠ',
      'ball | celebrate | celebration | confetti | party | woohoo',
    ),
    Emoji(
      'ðŸŽŽ',
      'celebration | doll | dolls | festival | Japanese',
    ),
    Emoji(
      'ðŸŽ',
      'carp | celebration | streamer',
    ),
    Emoji(
      'ðŸŽ',
      'bell | celebration | chime | wind',
    ),
    Emoji(
      'ðŸª©',
      'ball | dance | disco | glitter | mirror | party',
    ),
    Emoji(
      'ðŸ§§',
      'envelope | gift | good | hÃ³ngbÄo | lai | luck | money | red | see',
    ),
    Emoji(
      'ðŸŽ€',
      'celebration | ribbon',
    ),
    Emoji(
      'ðŸŽ',
      'birthday | bow | box | celebration | christmas | gift | present | surprise | wrapped',
    ),
    Emoji(
      'ðŸ”®',
      'ball | crystal | fairy | fairytale | fantasy | fortune | future | magic | tale | tool',
    ),
    Emoji(
      'ðŸ§¿',
      'amulet | bead | blue | charm | evil-eye | nazar | talisman',
    ),
    Emoji(
      'ðŸª¬',
      'amulet | Fatima | fortune | guide | hamsa | hand | Mary | Miriam | palm | protect | protection',
    ),
    Emoji(
      'ðŸ•¹ï¸',
      'game | joystick | video | videogame ',
    ),
    Emoji(
      'ðŸ§¸',
      'bear | plaything | plush | stuffed | teddy | toy',
    ),
    Emoji(
      'ðŸ–¼ï¸',
      'art | frame | framed | museum | painting | picture ',
    ),
    Emoji(
      'ðŸ§µ',
      'needle | sewing | spool | string | thread',
    ),
    Emoji(
      'ðŸ§¶',
      'ball | crochet | knit | yarn',
    ),
    Emoji(
      'ðŸ›ï¸',
      'bag | bags | hotel | shopping ',
    ),
    Emoji(
      'ðŸ“¿',
      'beads | clothing | necklace | prayer | religion',
    ),
    Emoji(
      'ðŸ’Ž',
      'diamond | engagement | gem | jewel | money | romance | stone | wedding',
    ),
    Emoji(
      'ðŸ“¯',
      'horn | post | postal',
    ),
    Emoji(
      'ðŸŽ™ï¸',
      'mic | microphone | music | studio ',
    ),
    Emoji(
      'ðŸŽšï¸',
      'level | music | slider ',
    ),
    Emoji(
      'ðŸŽ›ï¸',
      'control | knobs | music ',
    ),
    Emoji(
      'ðŸ“»',
      'entertainment | radio | tbt | video',
    ),
    Emoji(
      'ðŸ“±',
      'cell | communication | mobile | phone | telephone',
    ),
    Emoji(
      'ðŸ“²',
      'arrow | build | call | cell | communication | mobile | phone | receive | telephone',
    ),
    Emoji(
      'â˜Žï¸',
      'phone | telephone ',
    ),
    Emoji(
      'ðŸ“ž',
      'communication | phone | receiver | telephone | voip',
    ),
    Emoji(
      'ðŸ“Ÿ',
      'communication | pager',
    ),
    Emoji(
      'ðŸ“ ',
      'communication | fax | machine',
    ),
    Emoji(
      'ðŸ”‹',
      'battery',
    ),
    Emoji(
      'ðŸª«',
      'battery | drained | electronic | energy | low | power',
    ),
    Emoji(
      'ðŸ”Œ',
      'electric | electricity | plug',
    ),
    Emoji(
      'ðŸ’»',
      'computer | laptop | office | pc | personal',
    ),
    Emoji(
      'ðŸ–¥ï¸',
      'computer | desktop | monitor ',
    ),
    Emoji(
      'ðŸ–¨ï¸',
      'computer | printer ',
    ),
    Emoji(
      'âŒ¨ï¸',
      'computer | keyboard ',
    ),
    Emoji(
      'ðŸ–±ï¸',
      'computer | mouse ',
    ),
    Emoji(
      'ðŸ–²ï¸',
      'computer | trackball ',
    ),
    Emoji(
      'ðŸ’½',
      'computer | disk | minidisk | optical',
    ),
    Emoji(
      'ðŸ’¾',
      'computer | disk | floppy',
    ),
    Emoji(
      'ðŸ’¿',
      'blu-ray | CD | computer | disk | dvd | optical',
    ),
    Emoji(
      'ðŸ“€',
      'Blu-ray | cd | computer | disk | DVD | optical',
    ),
    Emoji(
      'ðŸ§®',
      'abacus | calculation | calculator',
    ),
    Emoji(
      'ðŸŽ¥',
      'bollywood | camera | cinema | film | hollywood | movie | record',
    ),
    Emoji(
      'ðŸŽžï¸',
      'cinema | film | frames | movie ',
    ),
    Emoji(
      'ðŸ“½ï¸',
      'cinema | film | movie | projector | video ',
    ),
    Emoji(
      'ðŸ“º',
      'television | tv | video',
    ),
    Emoji(
      'ðŸ“·',
      'camera | photo | selfie | snap | tbt | trip | video',
    ),
    Emoji(
      'ðŸ“¸',
      'camera | flash | video',
    ),
    Emoji(
      'ðŸ“¹',
      'camcorder | camera | tbt | video',
    ),
    Emoji(
      'ðŸ“¼',
      'old | school | tape | vcr | vhs | video | videocassette',
    ),
    Emoji(
      'ðŸ”',
      'glass | lab | left | left-pointing | magnifying | science | search | tilted | tool',
    ),
    Emoji(
      'ðŸ”Ž',
      'contact | glass | lab | magnifying | right | right-pointing | science | search | tilted | tool',
    ),
    Emoji(
      'ðŸ•¯ï¸',
      'candle | light ',
    ),
    Emoji(
      'ðŸ’¡',
      'bulb | comic | electric | idea | light',
    ),
    Emoji(
      'ðŸ”¦',
      'electric | flashlight | light | tool | torch',
    ),
    Emoji(
      'ðŸ®',
      'bar | lantern | light | paper | red | restaurant',
    ),
    Emoji(
      'ðŸ“”',
      'book | cover | decorated | decorative | education | notebook | school | writing',
    ),
    Emoji(
      'ðŸ“•',
      'book | closed | education',
    ),
    Emoji(
      'ðŸ“–',
      'book | education | fantasy | knowledge | library | novels | open | reading',
    ),
    Emoji(
      'ðŸ“—',
      'book | education | fantasy | green | library | reading',
    ),
    Emoji(
      'ðŸ“˜',
      'blue | book | education | fantasy | library | reading',
    ),
    Emoji(
      'ðŸ“™',
      'book | education | fantasy | library | orange | reading',
    ),
    Emoji(
      'ðŸ“š',
      'book | books | education | fantasy | knowledge | library | novels | reading | school | study',
    ),
    Emoji(
      'ðŸ““',
      'notebook',
    ),
    Emoji(
      'ðŸ“ƒ',
      'curl | document | page | paper',
    ),
    Emoji(
      'ðŸ“œ',
      'paper | scroll',
    ),
    Emoji(
      'ðŸ“„',
      'document | facing | page | paper | up',
    ),
    Emoji(
      'ðŸ“°',
      'communication | news | newspaper | paper',
    ),
    Emoji(
      'ðŸ—žï¸',
      'news | newspaper | paper | rolled | rolled-up ',
    ),
    Emoji(
      'ðŸ“‘',
      'bookmark | mark | marker | tabs',
    ),
    Emoji(
      'ðŸ”–',
      'bookmark | mark',
    ),
    Emoji(
      'ðŸ·ï¸',
      'label | tag ',
    ),
    Emoji(
      'ðŸ’°',
      'bag | bank | bet | billion | cash | cost | dollar | gold | million | money | moneybag | paid | paying | pot | rich | win',
    ),
    Emoji(
      'ðŸ’´',
      'bank | banknote | bill | currency | money | note | yen',
    ),
    Emoji(
      'ðŸ’µ',
      'bank | banknote | bill | currency | dollar | money | note',
    ),
    Emoji(
      'ðŸ’¶',
      '100 | bank | banknote | bill | currency | euro | money | note | rich',
    ),
    Emoji(
      'ðŸ’·',
      'bank | banknote | bill | billion | cash | currency | money | note | pound | pounds',
    ),
    Emoji(
      'ðŸ’¸',
      'bank | banknote | bill | billion | cash | dollar | fly | million | money | note | pay | wings',
    ),
    Emoji(
      'ðŸ’³',
      'bank | card | cash | charge | credit | money | pay',
    ),
    Emoji(
      'ðŸªª',
      'card | credentials | document | ID | identification | license | security',
    ),
    Emoji(
      'ðŸ§¾',
      'accounting | bookkeeping | evidence | invoice | proof | receipt',
    ),
    Emoji(
      'âœ‰ï¸',
      'e-mail | email | envelope | letter ',
    ),
    Emoji(
      'ðŸ“§',
      'e-mail | email | letter | mail',
    ),
    Emoji(
      'ðŸ“¨',
      'delivering | e-mail | email | envelope | incoming | letter | mail | receive | sent',
    ),
    Emoji(
      'ðŸ“©',
      'arrow | communication | down | e-mail | email | envelope | letter | mail | outgoing | send | sent',
    ),
    Emoji(
      'ðŸ“¤',
      'box | email | letter | mail | outbox | sent | tray',
    ),
    Emoji(
      'ðŸ“¥',
      'box | email | inbox | letter | mail | receive | tray | zero',
    ),
    Emoji(
      'ðŸ“¦',
      'box | communication | delivery | package | parcel | shipping',
    ),
    Emoji(
      'ðŸ“«',
      'closed | communication | flag | mail | mailbox | postbox | raised',
    ),
    Emoji(
      'ðŸ“ª',
      'closed | flag | lowered | mail | mailbox | postbox',
    ),
    Emoji(
      'ðŸ“¬',
      'flag | mail | mailbox | open | postbox | raised',
    ),
    Emoji(
      'ðŸ“­',
      'flag | lowered | mail | mailbox | open | postbox',
    ),
    Emoji(
      'ðŸ“®',
      'mail | mailbox | postbox',
    ),
    Emoji(
      'ðŸ—³ï¸',
      'ballot | box ',
    ),
    Emoji(
      'âœï¸',
      'pencil ',
    ),
    Emoji(
      'âœ’ï¸',
      'black | nib | pen ',
    ),
    Emoji(
      'ðŸ–‹ï¸',
      'fountain | pen ',
    ),
    Emoji(
      'ðŸ–Šï¸',
      'ballpoint | pen ',
    ),
    Emoji(
      'ðŸ–Œï¸',
      'paintbrush | painting ',
    ),
    Emoji(
      'ðŸ–ï¸',
      'crayon ',
    ),
    Emoji(
      'ðŸ“',
      'communication | media | memo | notes | pencil',
    ),
    Emoji(
      'ðŸ“',
      'file | folder',
    ),
    Emoji(
      'ðŸ“‚',
      'file | folder | open',
    ),
    Emoji(
      'ðŸ—‚ï¸',
      'card | dividers | index ',
    ),
    Emoji(
      'ðŸ“…',
      'calendar | date',
    ),
    Emoji(
      'ðŸ“†',
      'calendar | tear-off',
    ),
    Emoji(
      'ðŸ—’ï¸',
      'note | notepad | pad | spiral ',
    ),
    Emoji(
      'ðŸ—“ï¸',
      'calendar | pad | spiral ',
    ),
    Emoji(
      'ðŸ“‡',
      'card | index | old | rolodex | school',
    ),
    Emoji(
      'ðŸ“ˆ',
      'chart | data | graph | growth | increasing | right | trend | up | upward',
    ),
    Emoji(
      'ðŸ“‰',
      'chart | data | decreasing | down | downward | graph | negative | trend',
    ),
    Emoji(
      'ðŸ“Š',
      'bar | chart | data | graph',
    ),
    Emoji(
      'ðŸ“‹',
      'clipboard | do | list | notes',
    ),
    Emoji(
      'ðŸ“Œ',
      'collage | pin | pushpin',
    ),
    Emoji(
      'ðŸ“',
      'location | map | pin | pushpin | round',
    ),
    Emoji(
      'ðŸ“Ž',
      'paperclip',
    ),
    Emoji(
      'ðŸ–‡ï¸',
      'link | linked | paperclip | paperclips ',
    ),
    Emoji(
      'ðŸ“',
      'angle | edge | math | ruler | straight | straightedge',
    ),
    Emoji(
      'ðŸ“',
      'angle | math | rule | ruler | set | slide | triangle | triangular',
    ),
    Emoji(
      'âœ‚ï¸',
      'cut | cutting | paper | scissors | tool ',
    ),
    Emoji(
      'ðŸ—ƒï¸',
      'box | card | file ',
    ),
    Emoji(
      'ðŸ—„ï¸',
      'cabinet | file | filing | paper ',
    ),
    Emoji(
      'ðŸ—‘ï¸',
      'can | garbage | trash | waste | wastebasket ',
    ),
    Emoji(
      'ðŸ”’',
      'closed | lock | locked | private',
    ),
    Emoji(
      'ðŸ”“',
      'cracked | lock | open | unlock | unlocked',
    ),
    Emoji(
      'ðŸ”',
      'ink | lock | locked | nib | pen | privacy',
    ),
    Emoji(
      'ðŸ”',
      'bike | closed | key | lock | locked | secure',
    ),
    Emoji(
      'ðŸ”‘',
      'key | keys | lock | major | password | unlock',
    ),
    Emoji(
      'ðŸ—ï¸',
      'clue | key | lock | old ',
    ),
    Emoji(
      'ðŸ”¨',
      'hammer | home | improvement | repairs | tool',
    ),
    Emoji(
      'â›ï¸',
      'hammer | mining | pick | tool ',
    ),
    Emoji(
      'âš’ï¸',
      'hammer | pick | tool ',
    ),
    Emoji(
      'ðŸ› ï¸',
      'hammer | spanner | tool | wrench ',
    ),
    Emoji(
      'ðŸ”ª',
      'chef | cooking | hocho | kitchen | knife | tool | weapon',
    ),
    Emoji(
      'ðŸ—¡ï¸',
      'dagger | knife | weapon ',
    ),
    Emoji(
      'âš”ï¸',
      'crossed | swords | weapon ',
    ),
    Emoji(
      'ðŸ”«',
      'gun | handgun | pistol | revolver | tool | water | weapon',
    ),
    Emoji(
      'ðŸ›¡ï¸',
      'shield | weapon ',
    ),
    Emoji(
      'ðŸ”§',
      'home | improvement | spanner | tool | wrench',
    ),
    Emoji(
      'ðŸ”©',
      'bolt | home | improvement | nut | tool',
    ),
    Emoji(
      'âš™ï¸',
      'cog | cogwheel | gear | tool ',
    ),
    Emoji(
      'ðŸ—œï¸',
      'clamp | compress | tool | vice ',
    ),
    Emoji(
      'âš–ï¸',
      'balance | justice | Libra | scale | scales | tool | weight | zodiac ',
    ),
    Emoji(
      'ðŸ”—',
      'link | links',
    ),
    Emoji(
      'â›“ï¸',
      'chain | chains ',
    ),
    Emoji(
      'ðŸ§°',
      'box | chest | mechanic | red | tool | toolbox',
    ),
    Emoji(
      'ðŸ§²',
      'attraction | horseshoe | magnet | magnetic | negative | positive | shape | u',
    ),
    Emoji(
      'âš—ï¸',
      'alembic | chemistry | tool ',
    ),
    Emoji(
      'ðŸ§ª',
      'chemist | chemistry | experiment | lab | science | test | tube',
    ),
    Emoji(
      'ðŸ§«',
      'bacteria | biologist | biology | culture | dish | lab | petri',
    ),
    Emoji(
      'ðŸ§¬',
      'biologist | dna | evolution | gene | genetics | life',
    ),
    Emoji(
      'ðŸ”¬',
      'experiment | lab | microscope | science | tool',
    ),
    Emoji(
      'ðŸ©»',
      'bones | doctor | medical | skeleton | skull | x-ray | xray',
    ),
    Emoji(
      'ðŸ”­',
      'contact | extraterrestrial | science | telescope | tool',
    ),
    Emoji(
      'ðŸ“¡',
      'aliens | antenna | contact | dish | satellite | science',
    ),
    Emoji(
      'ðŸ’‰',
      'doctor | flu | medicine | needle | shot | sick | syringe | tool | vaccination',
    ),
    Emoji(
      'ðŸ’Š',
      'doctor | drugs | medicated | medicine | pill | pills | sick | vitamin',
    ),
    Emoji(
      'ðŸšª',
      'back | closet | door | front',
    ),
    Emoji(
      'ðŸ›ï¸',
      'bed | hotel | sleep ',
    ),
    Emoji(
      'ðŸ›‹ï¸',
      'couch | hotel | lamp ',
    ),
    Emoji(
      'ðŸš½',
      'bathroom | toilet',
    ),
    Emoji(
      'ðŸš¿',
      'shower | water',
    ),
    Emoji(
      'ðŸ›',
      'bath | bathtub',
    ),
    Emoji(
      'ðŸ§´',
      'bottle | lotion | moisturizer | shampoo | sunscreen',
    ),
    Emoji(
      'ðŸ§·',
      'diaper | pin | punk | rock | safety',
    ),
    Emoji(
      'ðŸ§¹',
      'broom | cleaning | sweeping | witch',
    ),
    Emoji(
      'ðŸ§º',
      'basket | farming | laundry | picnic',
    ),
    Emoji(
      'ðŸ§»',
      'paper | roll | toilet | towels',
    ),
    Emoji(
      'ðŸ§¼',
      'bar | bathing | clean | cleaning | lather | soap | soapdish',
    ),
    Emoji(
      'ðŸ§½',
      'absorbing | cleaning | porous | soak | sponge',
    ),
    Emoji(
      'ðŸ§¯',
      'extinguish | extinguisher | fire | quench',
    ),
    Emoji(
      'ðŸš¬',
      'cigarette | smoking',
    ),
    Emoji(
      'âš°ï¸',
      'coffin | dead | death | vampire ',
    ),
    Emoji(
      'âš±ï¸',
      'ashes | death | funeral | urn ',
    ),
    Emoji(
      'ðŸš°',
      'drinking | potable | water',
    ),
  ]),

// ======================================================= Category.SYMBOLS
  CategoryEmoji(Category.SYMBOLS, [
    Emoji(
      'ðŸ’˜',
      '143 | adorbs | arrow | cupid | date | emotion | heart | ily | love | romance | valentine',
    ),
    Emoji(
      'ðŸ’',
      '143 | anniversary | emotion | heart | ily | kisses | ribbon | valentine | xoxo',
    ),
    Emoji(
      'ðŸ’–',
      '143 | emotion | excited | good | heart | ily | kisses | morning | night | sparkle | sparkling | xoxo',
    ),
    Emoji(
      'ðŸ’—',
      '143 | emotion | excited | growing | heart | heartpulse | ily | kisses | muah | nervous | pulse | xoxo',
    ),
    Emoji(
      'ðŸ’“',
      '143 | beating | cardio | emotion | heart | heartbeat | ily | love | pulsating | pulse',
    ),
    Emoji(
      'ðŸ’ž',
      '143 | adorbs | anniversary | emotion | heart | hearts | revolving',
    ),
    Emoji(
      'ðŸ’•',
      '143 | anniversary | date | dating | emotion | heart | hearts | ily | kisses | love | loving | two | xoxo',
    ),
    Emoji(
      'ðŸ’Ÿ',
      '143 | decoration | emotion | heart | hearth | purple | white',
    ),
    Emoji(
      'â£ï¸',
      'exclamation | heart | heavy | mark | punctuation ',
    ),
    Emoji(
      'ðŸ’”',
      'break | broken | crushed | emotion | heart | heartbroken | lonely | sad',
    ),
    Emoji(
      'â¤ï¸â€ðŸ”¥',
      'emotion | heart | fire | fiery | love | red',
    ),
    Emoji(
      'â¤ï¸',
      'emotion | heart | love | red ',
    ),
    Emoji(
      'ðŸ§¡',
      '143 | heart | orange',
    ),
    Emoji(
      'ðŸ’›',
      '143 | cardiac | emotion | heart | ily | love | yellow',
    ),
    Emoji(
      'ðŸ’š',
      '143 | emotion | green | heart | ily | love | romantic',
    ),
    Emoji(
      'ðŸ’™',
      '143 | blue | emotion | heart | ily | love | romance',
    ),
    Emoji(
      'ðŸ’œ',
      '143 | bestest | emotion | heart | ily | love | purple',
    ),
    Emoji(
      'ðŸ–¤',
      'black | evil | heart | wicked',
    ),
    Emoji(
      'ðŸ’¯',
      '100 | a+ | agree | clearly | definitely | faithful | fleek | full | hundred | keep | perfect | point | score | TRUE | truth | yup',
    ),
    Emoji(
      'ðŸ’¢',
      'anger | angry | comic | mad | symbol | upset',
    ),
    Emoji(
      'ðŸ’¬',
      'balloon | bubble | comic | dialog | message | sms | speech | talk | text | typing',
    ),
    Emoji(
      'ðŸ‘ï¸â€ðŸ—¨ï¸',
      '1 | body | eye | one balloon | bubble | dialog | left | speech ',
    ),
    Emoji(
      'ðŸ—¯ï¸',
      'anger | angry | balloon | bubble | mad | right ',
    ),
    Emoji(
      'ðŸ’­',
      'balloon | bubble | cartoon | cloud | comic | daydream | decisions | dream | idea | invent | invention | realize | think | thoughts | wonder',
    ),
    Emoji(
      'ðŸ’¤',
      'comic | good | goodnight | night | sleep | sleeping | sleepy | tired | zzz',
    ),
    Emoji(
      'ðŸ’®',
      'flower | white',
    ),
    Emoji(
      'â™¨ï¸',
      'hot | hotsprings | springs | steaming ',
    ),
    Emoji(
      'ðŸ’ˆ',
      'barber | cut | fresh | haircut | pole | shave',
    ),
    Emoji(
      'ðŸ›‘',
      'octagonal | sign | stop',
    ),
    Emoji(
      'ðŸ•›',
      '12 | 12',
    ),
    Emoji(
      'ðŸ•§',
      '12 | 12',
    ),
    Emoji(
      'ðŸ•',
      '1 | 1',
    ),
    Emoji(
      'ðŸ•œ',
      '1 | 1',
    ),
    Emoji(
      'ðŸ•‘',
      '2 | 2',
    ),
    Emoji(
      'ðŸ•',
      '2 | 2',
    ),
    Emoji(
      'ðŸ•’',
      '3 | 3',
    ),
    Emoji(
      'ðŸ•ž',
      '3 | 3',
    ),
    Emoji(
      'ðŸ•“',
      '4 | 4',
    ),
    Emoji(
      'ðŸ•Ÿ',
      '30 | 4 | 4',
    ),
    Emoji(
      'ðŸ•”',
      '5 | 5',
    ),
    Emoji(
      'ðŸ• ',
      '30 | 5 | 5',
    ),
    Emoji(
      'ðŸ••',
      '6 | 6',
    ),
    Emoji(
      'ðŸ•¡',
      '30 | 6 | 6',
    ),
    Emoji(
      'ðŸ•–',
      '0 | 7 | 7',
    ),
    Emoji(
      'ðŸ•¢',
      '30 | 7 | 7',
    ),
    Emoji(
      'ðŸ•—',
      '8 | 8',
    ),
    Emoji(
      'ðŸ•£',
      '30 | 8 | 8',
    ),
    Emoji(
      'ðŸ•˜',
      '9 | 9',
    ),
    Emoji(
      'ðŸ•¤',
      '30 | 9 | 9',
    ),
    Emoji(
      'ðŸ•™',
      '0 | 10 | 10',
    ),
    Emoji(
      'ðŸ•¥',
      '10 | 10',
    ),
    Emoji(
      'ðŸ•š',
      '11 | 11',
    ),
    Emoji(
      'ðŸ•¦',
      '11 | 11',
    ),
    Emoji(
      'ðŸŒ€',
      'cyclone | dizzy | hurricane | twister | typhoon | weather',
    ),
    Emoji(
      'â™ ï¸',
      'card | game | spade | suit ',
    ),
    Emoji(
      'â™¥ï¸',
      'card | emotion | game | heart | hearts | suit ',
    ),
    Emoji(
      'â™¦ï¸',
      'card | diamond | game | suit ',
    ),
    Emoji(
      'â™£ï¸',
      'card | club | clubs | game | suit ',
    ),
    Emoji(
      'ðŸƒ',
      'card | game | joker | wildcard',
    ),
    Emoji(
      'ðŸ€„',
      'dragon | game | mahjong | red',
    ),
    Emoji(
      'ðŸŽ´',
      'card | cards | flower | game | Japanese | playing',
    ),
    Emoji(
      'ðŸ”‡',
      'mute | muted | quiet | silent | sound | speaker',
    ),
    Emoji(
      'ðŸ”ˆ',
      'low | soft | sound | speaker | volume',
    ),
    Emoji(
      'ðŸ”‰',
      'medium | sound | speaker | volume',
    ),
    Emoji(
      'ðŸ”Š',
      'high | loud | music | sound | speaker | volume',
    ),
    Emoji(
      'ðŸ“¢',
      'address | communication | loud | loudspeaker | public | sound',
    ),
    Emoji(
      'ðŸ“£',
      'cheering | megaphone | sound',
    ),
    Emoji(
      'ðŸ“¯',
      'horn | post | postal',
    ),
    Emoji(
      'ðŸ””',
      'bell | break | church | sound',
    ),
    Emoji(
      'ðŸ”•',
      'bell | forbidden | mute | no | not | prohibited | quiet | silent | slash | sound',
    ),
    Emoji(
      'ðŸŽµ',
      'music | musical | note | sound',
    ),
    Emoji(
      'ðŸŽ¶',
      'music | musical | note | notes | sound',
    ),
    Emoji(
      'ðŸ§',
      'ATM | automated | bank | cash | money | sign | teller',
    ),
    Emoji(
      'ðŸš®',
      'bin | litter | litterbin | sign',
    ),
    Emoji(
      'ðŸš°',
      'drinking | potable | water',
    ),
    Emoji(
      'â™¿',
      'access | handicap | symbol | wheelchair',
    ),
    Emoji(
      'ðŸ©¼',
      'aid | cane | crutch | disability | help | hurt | injured | mobility | stick',
    ),
    Emoji(
      'ðŸš¹',
      'bathroom | lavatory | man | menâ€™s | restroom | room | toilet | WC',
    ),
    Emoji(
      'ðŸšº',
      'bathroom | lavatory | restroom | room | toilet | WC | woman | womenâ€™s',
    ),
    Emoji(
      'ðŸš»',
      'bathroom | lavatory | restroom | toilet | WC',
    ),
    Emoji(
      'ðŸš¼',
      'baby | changing | symbol',
    ),
    Emoji(
      'ðŸš¾',
      'bathroom | closet | lavatory | restroom | toilet | water | WC',
    ),
    Emoji(
      'âš ï¸',
      'caution | warning ',
    ),
    Emoji(
      'ðŸš¸',
      'child | children | crossing | pedestrian | traffic',
    ),
    Emoji(
      'â›”',
      'do | entry | fail | forbidden | no | not | pass | prohibited | traffic',
    ),
    Emoji(
      'ðŸš«',
      'entry | forbidden | no | not | prohibited | smoke',
    ),
    Emoji(
      'ðŸš³',
      'bicycle | bicycles | bike | forbidden | no | not | prohibited',
    ),
    Emoji(
      'ðŸš­',
      'forbidden | no | not | prohibited | smoke | smoking',
    ),
    Emoji(
      'ðŸš¯',
      'forbidden | litter | littering | no | not | prohibited',
    ),
    Emoji(
      'ðŸš±',
      'dry | non-drinking | non-potable | prohibited | water',
    ),
    Emoji(
      'ðŸš·',
      'forbidden | no | not | pedestrian | pedestrians | prohibited',
    ),
    Emoji(
      'ðŸ”ž',
      '18 | age | eighteen | forbidden | no | not | one | prohibited | restriction | underage',
    ),
    Emoji(
      'â˜¢ï¸',
      'radioactive | sign ',
    ),
    Emoji(
      'â˜£ï¸',
      'biohazard | sign ',
    ),
    Emoji(
      'â¬†ï¸',
      'arrow | cardinal | direction | north | up ',
    ),
    Emoji(
      'â†—ï¸',
      'arrow | direction | intercardinal | northeast | up-right ',
    ),
    Emoji(
      'âž¡ï¸',
      'arrow | cardinal | direction | east | right ',
    ),
    Emoji(
      'â†˜ï¸',
      'arrow | direction | down-right | intercardinal | southeast ',
    ),
    Emoji(
      'â¬‡ï¸',
      'arrow | cardinal | direction | down | south ',
    ),
    Emoji(
      'â†™ï¸',
      'arrow | direction | down-left | intercardinal | southwest ',
    ),
    Emoji(
      'â¬…ï¸',
      'arrow | cardinal | direction | left | west ',
    ),
    Emoji(
      'â†–ï¸',
      'arrow | direction | intercardinal | northwest | up-left ',
    ),
    Emoji(
      'â†•ï¸',
      'arrow | up-down ',
    ),
    Emoji(
      'â†”ï¸',
      'arrow | left-right ',
    ),
    Emoji(
      'â†©ï¸',
      'arrow | curving | left | right ',
    ),
    Emoji(
      'â†ªï¸',
      'arrow | curving | left | right ',
    ),
    Emoji(
      'â¤´ï¸',
      'arrow | curving | right | up ',
    ),
    Emoji(
      'â¤µï¸',
      'arrow | curving | down | right ',
    ),
    Emoji(
      'ðŸ”ƒ',
      'arrow | arrows | clockwise | refresh | reload | vertical',
    ),
    Emoji(
      'ðŸ”„',
      'again | anticlockwise | arrow | arrows | button | counterclockwise | deja | refresh | rewindershins | vu',
    ),
    Emoji(
      'ðŸ”™',
      'arrow | BACK',
    ),
    Emoji(
      'ðŸ”š',
      'arrow | END',
    ),
    Emoji(
      'ðŸ”›',
      'arrow | mark | ON!',
    ),
    Emoji(
      'ðŸ”œ',
      'arrow | brb | omw | SOON',
    ),
    Emoji(
      'ðŸ”',
      'arrow | homie | TOP | up',
    ),
    Emoji(
      'ðŸ›',
      'place | pray | religion | worship',
    ),
    Emoji(
      'âš›ï¸',
      'atheist | atom | symbol ',
    ),
    Emoji(
      'ðŸ•‰ï¸',
      'Hindu | om | religion ',
    ),
    Emoji(
      'âœ¡ï¸',
      'David | Jew | Jewish | judaism | religion | star ',
    ),
    Emoji(
      'â˜¸ï¸',
      'Buddhist | dharma | religion | wheel ',
    ),
    Emoji(
      'â˜¯ï¸',
      'difficult | lives | religion | tao | taoist | total | yang | yin | yinyang ',
    ),
    Emoji(
      'âœï¸',
      'christ | Christian | cross | latin | religion ',
    ),
    Emoji(
      'â˜¦ï¸',
      'Christian | cross | orthodox | religion ',
    ),
    Emoji(
      'â˜ªï¸',
      'crescent | islam | Muslim | ramadan | religion | star ',
    ),
    Emoji(
      'â˜®ï¸',
      'healing | peace | peaceful | symbol ',
    ),
    Emoji(
      'ðŸ•Ž',
      'candelabrum | candlestick | hanukkah | jewish | judaism | menorah | religion',
    ),
    Emoji(
      'ðŸ”¯',
      'dotted | fortune | jewish | judaism | six-pointed | star',
    ),
    Emoji(
      'â™ˆ',
      'Aries | horoscope | ram | zodiac',
    ),
    Emoji(
      'â™‰',
      'bull | horoscope | ox | Taurus | zodiac',
    ),
    Emoji(
      'â™Š',
      'Gemini | horoscope | twins | zodiac',
    ),
    Emoji(
      'â™‹',
      'Cancer | crab | horoscope | zodiac',
    ),
    Emoji(
      'â™Œ',
      'horoscope | Leo | lion | zodiac',
    ),
    Emoji(
      'â™',
      'horoscope | Virgo | zodiac',
    ),
    Emoji(
      'â™Ž',
      'balance | horoscope | justice | Libra | scales | zodiac',
    ),
    Emoji(
      'â™',
      'horoscope | Scorpio | scorpion | Scorpius | zodiac',
    ),
    Emoji(
      'â™',
      'archer | horoscope | Sagittarius | zodiac',
    ),
    Emoji(
      'â™‘',
      'Capricorn | goat | horoscope | zodiac',
    ),
    Emoji(
      'â™’',
      'Aquarius | bearer | horoscope | water | zodiac',
    ),
    Emoji(
      'â™“',
      'fish | horoscope | Pisces | zodiac',
    ),
    Emoji(
      'â›Ž',
      'bearer | Ophiuchus | serpent | snake | zodiac',
    ),
    Emoji(
      'ðŸ”€',
      'arrow | button | crossed | shuffle | tracks',
    ),
    Emoji(
      'ðŸ”',
      'arrow | button | clockwise | repeat',
    ),
    Emoji(
      'ðŸ”‚',
      'arrow | button | clockwise | once | repeat | single',
    ),
    Emoji(
      'â–¶ï¸',
      'arrow | button | play | right | triangle ',
    ),
    Emoji(
      'â©',
      'arrow | button | double | fast | fast-forward | forward',
    ),
    Emoji(
      'â—€ï¸',
      'arrow | button | left | reverse | triangle ',
    ),
    Emoji(
      'âª',
      'arrow | button | double | fast | reverse | rewind',
    ),
    Emoji(
      'ðŸ”¼',
      'arrow | button | red | up | upwards',
    ),
    Emoji(
      'â«',
      'arrow | button | double | fast | up',
    ),
    Emoji(
      'ðŸ”½',
      'arrow | button | down | downwards | red',
    ),
    Emoji(
      'â¬',
      'arrow | button | double | down | fast',
    ),
    Emoji(
      'â¹ï¸',
      'button | square | stop ',
    ),
    Emoji(
      'âï¸',
      'button | eject ',
    ),
    Emoji(
      'ðŸŽ¦',
      'camera | cinema | film | movie',
    ),
    Emoji(
      'ðŸ”…',
      'brightness | button | dim | low',
    ),
    Emoji(
      'ðŸ”†',
      'bright | brightness | button | light',
    ),
    Emoji(
      'ðŸ“¶',
      'antenna | bar | bars | cell | communication | mobile | phone | signal | telephone',
    ),
    Emoji(
      'ðŸ“³',
      'cell | communication | mobile | mode | phone | telephone | vibration',
    ),
    Emoji(
      'ðŸ“´',
      'cell | mobile | off | phone | telephone',
    ),
    Emoji(
      'â™¾ï¸',
      'forever | infinity | unbounded | universal ',
    ),
    Emoji(
      'â™»ï¸',
      'recycle | recycling | symbol ',
    ),
    Emoji(
      'ðŸ”±',
      'anchor | emblem | poseidon | ship | tool | trident',
    ),
    Emoji(
      'ðŸ“›',
      'badge | name',
    ),
    Emoji(
      'ðŸ”°',
      'beginner | chevron | green | Japanese | leaf | symbol | tool | yellow',
    ),
    Emoji(
      'â­•',
      'circle | heavy | hollow | large | o | red',
    ),
    Emoji(
      'âœ…',
      'âœ“ | button | check | checked | checkmark | complete | completed | done | fixed | mark | tick',
    ),
    Emoji(
      'â˜‘ï¸',
      'âœ“ | ballot | box | check | checked | done | off | tick ',
    ),
    Emoji(
      'âœ”ï¸',
      'âœ“ | check | checked | checkmark | done | heavy | mark | tick ',
    ),
    Emoji(
      'âŒ',
      'Ã— | cancel | cross | mark | multiplication | multiply | x',
    ),
    Emoji(
      'âŽ',
      'Ã— | button | cross | mark | multiplication | multiply | square | x',
    ),
    Emoji(
      'âž•',
      '+ | plus',
    ),
    Emoji(
      'âž–',
      '- | âˆ’ | heavy | math | minus | sign',
    ),
    Emoji(
      'âž—',
      'Ã· | divide | division | heavy | math | sign',
    ),
    Emoji(
      'âœ–ï¸',
      'Ã— | cancel | multiplication | multiply | sign | x ',
    ),
    Emoji(
      'ðŸŸ°',
      'answer | equal | equality | equals | heavy | math | sign',
    ),
    Emoji(
      'âž°',
      'curl | curly | loop',
    ),
    Emoji(
      'âž¿',
      'curl | curly | double | loop',
    ),
    Emoji(
      'ã€½ï¸',
      'alternation | mark | part ',
    ),
    Emoji(
      'âœ³ï¸',
      '* | asterisk | eight-spoked ',
    ),
    Emoji(
      'âœ´ï¸',
      '* | eight-pointed | star ',
    ),
    Emoji(
      'â‡ï¸',
      '* | sparkle ',
    ),
    Emoji(
      'â€¼ï¸',
      '! | !! | bangbang | double | exclamation | mark | punctuation ',
    ),
    Emoji(
      'â‰ï¸',
      '! | !? | ? | exclamation | interrobang | mark | punctuation | question ',
    ),
    Emoji(
      'â“',
      '? | mark | punctuation | question | red',
    ),
    Emoji(
      'â”',
      '? | mark | outlined | punctuation | question | white',
    ),
    Emoji(
      'â•',
      '! | exclamation | mark | outlined | punctuation | white',
    ),
    Emoji(
      'â—',
      '! | exclamation | mark | punctuation | red',
    ),
    Emoji(
      'Â©ï¸',
      'C | copyright ',
    ),
    Emoji(
      'Â®ï¸',
      'R | registered ',
    ),
    Emoji(
      'â„¢ï¸',
      'mark | TM | trade | trademark ',
    ),
    Emoji(
      '#ï¸âƒ£',
      'Keycap Number Sign',
    ),
    Emoji(
      '0ï¸âƒ£',
      'Keycap Digit Zero',
    ),
    Emoji(
      '1ï¸âƒ£',
      'Keycap Digit One',
    ),
    Emoji(
      '2ï¸âƒ£',
      'Keycap Digit Two',
    ),
    Emoji(
      '3ï¸âƒ£',
      'Keycap Digit Three',
    ),
    Emoji(
      '4ï¸âƒ£',
      'Keycap Digit Four',
    ),
    Emoji(
      '5ï¸âƒ£',
      'Keycap Digit Five',
    ),
    Emoji(
      '6ï¸âƒ£',
      'Keycap Digit Six',
    ),
    Emoji(
      '7ï¸âƒ£',
      'Keycap Digit Seven',
    ),
    Emoji(
      '8ï¸âƒ£',
      'Keycap Digit Eight',
    ),
    Emoji(
      '9ï¸âƒ£',
      'Keycap Digit Nine',
    ),
    Emoji(
      'ðŸ”Ÿ',
      'Keycap: 10',
    ),
    Emoji(
      'ðŸ” ',
      'ABCD | input | latin | letters | uppercase',
    ),
    Emoji(
      'ðŸ”¡',
      'abcd | input | latin | letters | lowercase',
    ),
    Emoji(
      'ðŸ”¢',
      '1234 | input | numbers',
    ),
    Emoji(
      'ðŸ”£',
      '& | % | â™ª | ã€’ | input | symbols',
    ),
    Emoji(
      'ðŸ”¤',
      'abc | alphabet | input | latin | letters',
    ),
    Emoji(
      'ðŸ…°ï¸',
      'blood | button | type ',
    ),
    Emoji(
      'ðŸ†Ž',
      'AB | blood | button | type',
    ),
    Emoji(
      'ðŸ…±ï¸',
      'B | blood | button | type ',
    ),
    Emoji(
      'ðŸ†‘',
      'button | CL',
    ),
    Emoji(
      'ðŸ†’',
      'button | COOL',
    ),
    Emoji(
      'ðŸ†“',
      'button | FREE',
    ),
    Emoji(
      'â„¹ï¸',
      'I | information ',
    ),
    Emoji(
      'ðŸ†”',
      'button | ID | identity',
    ),
    Emoji(
      'â“‚ï¸',
      'circle | circled | M ',
    ),
    Emoji(
      'ðŸ†•',
      'button | NEW',
    ),
    Emoji(
      'ðŸ†–',
      'button | NG',
    ),
    Emoji(
      'ðŸ…¾ï¸',
      'blood | button | O | type ',
    ),
    Emoji(
      'ðŸ†—',
      'button | OK | okay',
    ),
    Emoji(
      'ðŸ…¿ï¸',
      'button | P | parking ',
    ),
    Emoji(
      'ðŸ†˜',
      'button | help | SOS',
    ),
    Emoji(
      'ðŸ†™',
      'button | mark | UP | UP!',
    ),
    Emoji(
      'ðŸ†š',
      'button | versus | VS',
    ),
    Emoji(
      'ðŸˆ',
      'button | here | Japanese | katakana',
    ),
    Emoji(
      'ðŸˆ‚ï¸',
      'button | charge | Japanese | katakana | service ',
    ),
    Emoji(
      'ðŸˆ·ï¸',
      'amount | button | ideograph | Japanese | monthly ',
    ),
    Emoji(
      'ðŸˆ¶',
      'button | charge | free | ideograph | Japanese | not',
    ),
    Emoji(
      'ðŸˆ¯',
      'button | ideograph | Japanese | reserved',
    ),
    Emoji(
      'ðŸ‰',
      'bargain | button | ideograph | Japanese',
    ),
    Emoji(
      'ðŸˆ¹',
      'button | discount | ideograph | Japanese',
    ),
    Emoji(
      'ðŸˆš',
      'button | charge | free | ideograph | Japanese',
    ),
    Emoji(
      'ðŸˆ²',
      'button | ideograph | Japanese | prohibited',
    ),
    Emoji(
      'ðŸ‰‘',
      'acceptable | button | ideograph | Japanese',
    ),
    Emoji(
      'ðŸˆ¸',
      'application | button | ideograph | Japanese',
    ),
    Emoji(
      'ðŸˆ´',
      'button | grade | ideograph | Japanese | passing',
    ),
    Emoji(
      'ðŸˆ³',
      'button | ideograph | Japanese | vacancy',
    ),
    Emoji(
      'ãŠ—ï¸',
      'button | congratulations | ideograph | Japanese ',
    ),
    Emoji(
      'ãŠ™ï¸',
      'button | ideograph | Japanese | secret ',
    ),
    Emoji(
      'ðŸˆº',
      'business | button | ideograph | Japanese | open',
    ),
    Emoji(
      'ðŸˆµ',
      'button | ideograph | Japanese | no | vacancy',
    ),
    Emoji(
      'ðŸ”´',
      'circle | geometric | red',
    ),
    Emoji(
      'ðŸ”µ',
      'blue | circle | geometric',
    ),
    Emoji(
      'âš«',
      'black | circle | geometric',
    ),
    Emoji(
      'âšª',
      'circle | geometric | white',
    ),
    Emoji(
      'â¬›',
      'black | geometric | large | square',
    ),
    Emoji(
      'â¬œ',
      'geometric | large | square | white',
    ),
    Emoji(
      'â—¼ï¸',
      'black | geometric | medium | square ',
    ),
    Emoji(
      'â—»ï¸',
      'geometric | medium | square | white ',
    ),
    Emoji(
      'â—¾',
      'black | geometric | medium-small | square',
    ),
    Emoji(
      'â—½',
      'geometric | medium-small | square | white',
    ),
    Emoji(
      'â–ªï¸',
      'black | geometric | small | square ',
    ),
    Emoji(
      'â–«ï¸',
      'geometric | small | square | white ',
    ),
    Emoji(
      'ðŸ”¶',
      'diamond | geometric | large | orange',
    ),
    Emoji(
      'ðŸ”·',
      'blue | diamond | geometric | large',
    ),
    Emoji(
      'ðŸ”¸',
      'diamond | geometric | orange | small',
    ),
    Emoji(
      'ðŸ”¹',
      'blue | diamond | geometric | small',
    ),
    Emoji(
      'ðŸ”º',
      'geometric | pointed | red | triangle | up',
    ),
    Emoji(
      'ðŸ”»',
      'down | geometric | pointed | red | triangle',
    ),
    Emoji(
      'ðŸ’ ',
      'comic | diamond | dot | geometric',
    ),
    Emoji(
      'ðŸ”³',
      'button | geometric | outlined | square | white',
    ),
    Emoji(
      'ðŸ”²',
      'black | button | geometric | square',
    ),
  ]),

// ======================================================= Category.FLAGS
  CategoryEmoji(Category.FLAGS, [
    Emoji(
      'ðŸ',
      'checkered | chequered | finish | flag | flags | game | race | racing | sport | win',
    ),
    Emoji(
      'ðŸš©',
      'construction | flag | golf | post | triangular',
    ),
    Emoji(
      'ðŸŽŒ',
      'celebration | cross | crossed | flags | Japanese',
    ),
    Emoji(
      'ðŸ´',
      'black | flag | waving',
    ),
    Emoji(
      'ðŸ³ï¸',
      'flag | waving | white ',
    ),
    Emoji(
      'ðŸ³ï¸â€ðŸŒˆ',
      'flag | waving | white gay | genderqueer | glbt | glbtq | lesbian | lgbt | lgbtq | lgbtqia | nature | pride | queer | rain | rainbow | trans | transgender | weather ',
    ),
    Emoji(
      'ðŸ³ï¸â€âš§ï¸',
      'flag | waving | white symbol | transgender ',
    ),
    Emoji(
      'ðŸ´â€â˜ ï¸',
      'black | flag | waving bone | crossbones | dead | death | face | monster | skull ',
    ),
    Emoji(
      'ðŸ‡¦ðŸ‡¨',
      'Flag: Ascension Island',
    ),
    Emoji(
      'ðŸ‡¦ðŸ‡©',
      'Flag: Andorra',
    ),
    Emoji(
      'ðŸ‡¦ðŸ‡ª',
      'Flag: United Arab Emirates',
    ),
    Emoji(
      'ðŸ‡¦ðŸ‡«',
      'Flag: Afghanistan',
    ),
    Emoji(
      'ðŸ‡¦ðŸ‡¬',
      'Flag: Antigua & Barbuda',
    ),
    Emoji(
      'ðŸ‡¦ðŸ‡®',
      'Flag: Anguilla',
    ),
    Emoji(
      'ðŸ‡¦ðŸ‡±',
      'Flag: Albania',
    ),
    Emoji(
      'ðŸ‡¦ðŸ‡²',
      'Flag: Armenia',
    ),
    Emoji(
      'ðŸ‡¦ðŸ‡´',
      'Flag: Angola',
    ),
    Emoji(
      'ðŸ‡¦ðŸ‡¶',
      'Flag: Antarctica',
    ),
    Emoji(
      'ðŸ‡¦ðŸ‡·',
      'Flag: Argentina',
    ),
    Emoji(
      'ðŸ‡¦ðŸ‡¸',
      'Flag: American Samoa',
    ),
    Emoji(
      'ðŸ‡¦ðŸ‡¹',
      'Flag: Austria',
    ),
    Emoji(
      'ðŸ‡¦ðŸ‡º',
      'Flag: Australia',
    ),
    Emoji(
      'ðŸ‡¦ðŸ‡¼',
      'Flag: Aruba',
    ),
    Emoji(
      'ðŸ‡¦ðŸ‡½',
      'Flag: Ã…land Islands',
    ),
    Emoji(
      'ðŸ‡¦ðŸ‡¿',
      'Flag: Azerbaijan',
    ),
    Emoji(
      'ðŸ‡§ðŸ‡¦',
      'Flag: Bosnia & Herzegovina',
    ),
    Emoji(
      'ðŸ‡§ðŸ‡§',
      'Flag: Barbados',
    ),
    Emoji(
      'ðŸ‡§ðŸ‡©',
      'Flag: Bangladesh',
    ),
    Emoji(
      'ðŸ‡§ðŸ‡ª',
      'Flag: Belgium',
    ),
    Emoji(
      'ðŸ‡§ðŸ‡«',
      'Flag: Burkina Faso',
    ),
    Emoji(
      'ðŸ‡§ðŸ‡¬',
      'Flag: Bulgaria',
    ),
    Emoji(
      'ðŸ‡§ðŸ‡­',
      'Flag: Bahrain',
    ),
    Emoji(
      'ðŸ‡§ðŸ‡®',
      'Flag: Burundi',
    ),
    Emoji(
      'ðŸ‡§ðŸ‡¯',
      'Flag: Benin',
    ),
    Emoji(
      'ðŸ‡§ðŸ‡±',
      'Flag: St. BarthÃ©lemy',
    ),
    Emoji(
      'ðŸ‡§ðŸ‡²',
      'Flag: Bermuda',
    ),
    Emoji(
      'ðŸ‡§ðŸ‡³',
      'Flag: Brunei',
    ),
    Emoji(
      'ðŸ‡§ðŸ‡´',
      'Flag: Bolivia',
    ),
    Emoji(
      'ðŸ‡§ðŸ‡¶',
      'Flag: Caribbean Netherlands',
    ),
    Emoji(
      'ðŸ‡§ðŸ‡·',
      'Flag: Brazil',
    ),
    Emoji(
      'ðŸ‡§ðŸ‡¸',
      'Flag: Bahamas',
    ),
    Emoji(
      'ðŸ‡§ðŸ‡¹',
      'Flag: Bhutan',
    ),
    Emoji(
      'ðŸ‡§ðŸ‡»',
      'Flag: Bouvet Island',
    ),
    Emoji(
      'ðŸ‡§ðŸ‡¼',
      'Flag: Botswana',
    ),
    Emoji(
      'ðŸ‡§ðŸ‡¾',
      'Flag: Belarus',
    ),
    Emoji(
      'ðŸ‡§ðŸ‡¿',
      'Flag: Belize',
    ),
    Emoji(
      'ðŸ‡¨ðŸ‡¦',
      'Flag: Canada',
    ),
    Emoji(
      'ðŸ‡¨ðŸ‡¨',
      'Flag: Cocos (Keeling) Islands',
    ),
    Emoji(
      'ðŸ‡¨ðŸ‡©',
      'Flag: Congo - Kinshasa',
    ),
    Emoji(
      'ðŸ‡¨ðŸ‡«',
      'Flag: Central African Republic',
    ),
    Emoji(
      'ðŸ‡¨ðŸ‡¬',
      'Flag: Congo - Brazzaville',
    ),
    Emoji(
      'ðŸ‡¨ðŸ‡­',
      'Flag: Switzerland',
    ),
    Emoji(
      'ðŸ‡¨ðŸ‡®',
      'Flag: CÃ´te dâ€™Ivoire',
    ),
    Emoji(
      'ðŸ‡¨ðŸ‡°',
      'Flag: Cook Islands',
    ),
    Emoji(
      'ðŸ‡¨ðŸ‡±',
      'Flag: Chile',
    ),
    Emoji(
      'ðŸ‡¨ðŸ‡²',
      'Flag: Cameroon',
    ),
    Emoji(
      'ðŸ‡¨ðŸ‡³',
      'Flag: China',
    ),
    Emoji(
      'ðŸ‡¨ðŸ‡´',
      'Flag: Colombia',
    ),
    Emoji(
      'ðŸ‡¨ðŸ‡µ',
      'Flag: Clipperton Island',
    ),
    Emoji(
      'ðŸ‡¨ðŸ‡·',
      'Flag: Costa Rica',
    ),
    Emoji(
      'ðŸ‡¨ðŸ‡º',
      'Flag: Cuba',
    ),
    Emoji(
      'ðŸ‡¨ðŸ‡»',
      'Flag: Cape Verde',
    ),
    Emoji(
      'ðŸ‡¨ðŸ‡¼',
      'Flag: CuraÃ§ao',
    ),
    Emoji(
      'ðŸ‡¨ðŸ‡½',
      'Flag: Christmas Island',
    ),
    Emoji(
      'ðŸ‡¨ðŸ‡¾',
      'Flag: Cyprus',
    ),
    Emoji(
      'ðŸ‡¨ðŸ‡¿',
      'Flag: Czechia',
    ),
    Emoji(
      'ðŸ‡©ðŸ‡ª',
      'Flag: Germany',
    ),
    Emoji(
      'ðŸ‡©ðŸ‡¬',
      'Flag: Diego Garcia',
    ),
    Emoji(
      'ðŸ‡©ðŸ‡¯',
      'Flag: Djibouti',
    ),
    Emoji(
      'ðŸ‡©ðŸ‡°',
      'Flag: Denmark',
    ),
    Emoji(
      'ðŸ‡©ðŸ‡²',
      'Flag: Dominica',
    ),
    Emoji(
      'ðŸ‡©ðŸ‡´',
      'Flag: Dominican Republic',
    ),
    Emoji(
      'ðŸ‡©ðŸ‡¿',
      'Flag: Algeria',
    ),
    Emoji(
      'ðŸ‡ªðŸ‡¦',
      'Flag: Ceuta & Melilla',
    ),
    Emoji(
      'ðŸ‡ªðŸ‡¨',
      'Flag: Ecuador',
    ),
    Emoji(
      'ðŸ‡ªðŸ‡ª',
      'Flag: Estonia',
    ),
    Emoji(
      'ðŸ‡ªðŸ‡¬',
      'Flag: Egypt',
    ),
    Emoji(
      'ðŸ‡ªðŸ‡­',
      'Flag: Western Sahara',
    ),
    Emoji(
      'ðŸ‡ªðŸ‡·',
      'Flag: Eritrea',
    ),
    Emoji(
      'ðŸ‡ªðŸ‡¸',
      'Flag: Spain',
    ),
    Emoji(
      'ðŸ‡ªðŸ‡¹',
      'Flag: Ethiopia',
    ),
    Emoji(
      'ðŸ‡ªðŸ‡º',
      'Flag: European Union',
    ),
    Emoji(
      'ðŸ‡«ðŸ‡®',
      'Flag: Finland',
    ),
    Emoji(
      'ðŸ‡«ðŸ‡¯',
      'Flag: Fiji',
    ),
    Emoji(
      'ðŸ‡«ðŸ‡°',
      'Flag: Falkland Islands',
    ),
    Emoji(
      'ðŸ‡«ðŸ‡²',
      'Flag: Micronesia',
    ),
    Emoji(
      'ðŸ‡«ðŸ‡´',
      'Flag: Faroe Islands',
    ),
    Emoji(
      'ðŸ‡«ðŸ‡·',
      'Flag: France',
    ),
    Emoji(
      'ðŸ‡¬ðŸ‡¦',
      'Flag: Gabon',
    ),
    Emoji(
      'ðŸ‡¬ðŸ‡§',
      'Flag: United Kingdom',
    ),
    Emoji(
      'ðŸ‡¬ðŸ‡©',
      'Flag: Grenada',
    ),
    Emoji(
      'ðŸ‡¬ðŸ‡ª',
      'Flag: Georgia',
    ),
    Emoji(
      'ðŸ‡¬ðŸ‡«',
      'Flag: French Guiana',
    ),
    Emoji(
      'ðŸ‡¬ðŸ‡¬',
      'Flag: Guernsey',
    ),
    Emoji(
      'ðŸ‡¬ðŸ‡­',
      'Flag: Ghana',
    ),
    Emoji(
      'ðŸ‡¬ðŸ‡®',
      'Flag: Gibraltar',
    ),
    Emoji(
      'ðŸ‡¬ðŸ‡±',
      'Flag: Greenland',
    ),
    Emoji(
      'ðŸ‡¬ðŸ‡²',
      'Flag: Gambia',
    ),
    Emoji(
      'ðŸ‡¬ðŸ‡³',
      'Flag: Guinea',
    ),
    Emoji(
      'ðŸ‡¬ðŸ‡µ',
      'Flag: Guadeloupe',
    ),
    Emoji(
      'ðŸ‡¬ðŸ‡¶',
      'Flag: Equatorial Guinea',
    ),
    Emoji(
      'ðŸ‡¬ðŸ‡·',
      'Flag: Greece',
    ),
    Emoji(
      'ðŸ‡¬ðŸ‡¸',
      'Flag: South Georgia & South Sandwich Islands',
    ),
    Emoji(
      'ðŸ‡¬ðŸ‡¹',
      'Flag: Guatemala',
    ),
    Emoji(
      'ðŸ‡¬ðŸ‡º',
      'Flag: Guam',
    ),
    Emoji(
      'ðŸ‡¬ðŸ‡¼',
      'Flag: Guinea-Bissau',
    ),
    Emoji(
      'ðŸ‡¬ðŸ‡¾',
      'Flag: Guyana',
    ),
    Emoji(
      'ðŸ‡­ðŸ‡°',
      'Flag: Hong Kong SAR China',
    ),
    Emoji(
      'ðŸ‡­ðŸ‡²',
      'Flag: Heard & McDonald Islands',
    ),
    Emoji(
      'ðŸ‡­ðŸ‡³',
      'Flag: Honduras',
    ),
    Emoji(
      'ðŸ‡­ðŸ‡·',
      'Flag: Croatia',
    ),
    Emoji(
      'ðŸ‡­ðŸ‡¹',
      'Flag: Haiti',
    ),
    Emoji(
      'ðŸ‡­ðŸ‡º',
      'Flag: Hungary',
    ),
    Emoji(
      'ðŸ‡®ðŸ‡¨',
      'Flag: Canary Islands',
    ),
    Emoji(
      'ðŸ‡®ðŸ‡©',
      'Flag: Indonesia',
    ),
    Emoji(
      'ðŸ‡®ðŸ‡ª',
      'Flag: Ireland',
    ),
    Emoji(
      'ðŸ‡®ðŸ‡±',
      'Flag: Israel',
    ),
    Emoji(
      'ðŸ‡®ðŸ‡²',
      'Flag: Isle of Man',
    ),
    Emoji(
      'ðŸ‡®ðŸ‡³',
      'Flag: India',
    ),
    Emoji(
      'ðŸ‡®ðŸ‡´',
      'Flag: British Indian Ocean Territory',
    ),
    Emoji(
      'ðŸ‡®ðŸ‡¶',
      'Flag: Iraq',
    ),
    Emoji(
      'ðŸ‡®ðŸ‡·',
      'Flag: Iran',
    ),
    Emoji(
      'ðŸ‡®ðŸ‡¸',
      'Flag: Iceland',
    ),
    Emoji(
      'ðŸ‡®ðŸ‡¹',
      'Flag: Italy',
    ),
    Emoji(
      'ðŸ‡¯ðŸ‡ª',
      'Flag: Jersey',
    ),
    Emoji(
      'ðŸ‡¯ðŸ‡²',
      'Flag: Jamaica',
    ),
    Emoji(
      'ðŸ‡¯ðŸ‡´',
      'Flag: Jordan',
    ),
    Emoji(
      'ðŸ‡¯ðŸ‡µ',
      'Flag: Japan',
    ),
    Emoji(
      'ðŸ‡°ðŸ‡ª',
      'Flag: Kenya',
    ),
    Emoji(
      'ðŸ‡°ðŸ‡¬',
      'Flag: Kyrgyzstan',
    ),
    Emoji(
      'ðŸ‡°ðŸ‡­',
      'Flag: Cambodia',
    ),
    Emoji(
      'ðŸ‡°ðŸ‡®',
      'Flag: Kiribati',
    ),
    Emoji(
      'ðŸ‡°ðŸ‡²',
      'Flag: Comoros',
    ),
    Emoji(
      'ðŸ‡°ðŸ‡³',
      'Flag: St. Kitts & Nevis',
    ),
    Emoji(
      'ðŸ‡°ðŸ‡µ',
      'Flag: North Korea',
    ),
    Emoji(
      'ðŸ‡°ðŸ‡·',
      'Flag: South Korea',
    ),
    Emoji(
      'ðŸ‡°ðŸ‡¼',
      'Flag: Kuwait',
    ),
    Emoji(
      'ðŸ‡°ðŸ‡¾',
      'Flag: Cayman Islands',
    ),
    Emoji(
      'ðŸ‡°ðŸ‡¿',
      'Flag: Kazakhstan',
    ),
    Emoji(
      'ðŸ‡±ðŸ‡¦',
      'Flag: Laos',
    ),
    Emoji(
      'ðŸ‡±ðŸ‡§',
      'Flag: Lebanon',
    ),
    Emoji(
      'ðŸ‡±ðŸ‡¨',
      'Flag: St. Lucia',
    ),
    Emoji(
      'ðŸ‡±ðŸ‡®',
      'Flag: Liechtenstein',
    ),
    Emoji(
      'ðŸ‡±ðŸ‡°',
      'Flag: Sri Lanka',
    ),
    Emoji(
      'ðŸ‡±ðŸ‡·',
      'Flag: Liberia',
    ),
    Emoji(
      'ðŸ‡±ðŸ‡¸',
      'Flag: Lesotho',
    ),
    Emoji(
      'ðŸ‡±ðŸ‡¹',
      'Flag: Lithuania',
    ),
    Emoji(
      'ðŸ‡±ðŸ‡º',
      'Flag: Luxembourg',
    ),
    Emoji(
      'ðŸ‡±ðŸ‡»',
      'Flag: Latvia',
    ),
    Emoji(
      'ðŸ‡±ðŸ‡¾',
      'Flag: Libya',
    ),
    Emoji(
      'ðŸ‡²ðŸ‡¦',
      'Flag: Morocco',
    ),
    Emoji(
      'ðŸ‡²ðŸ‡¨',
      'Flag: Monaco',
    ),
    Emoji(
      'ðŸ‡²ðŸ‡©',
      'Flag: Moldova',
    ),
    Emoji(
      'ðŸ‡²ðŸ‡ª',
      'Flag: Montenegro',
    ),
    Emoji(
      'ðŸ‡²ðŸ‡«',
      'Flag: St. Martin',
    ),
    Emoji(
      'ðŸ‡²ðŸ‡¬',
      'Flag: Madagascar',
    ),
    Emoji(
      'ðŸ‡²ðŸ‡­',
      'Flag: Marshall Islands',
    ),
    Emoji(
      'ðŸ‡²ðŸ‡°',
      'Flag: North Macedonia',
    ),
    Emoji(
      'ðŸ‡²ðŸ‡±',
      'Flag: Mali',
    ),
    Emoji(
      'ðŸ‡²ðŸ‡²',
      'Flag: Myanmar (Burma)',
    ),
    Emoji(
      'ðŸ‡²ðŸ‡³',
      'Flag: Mongolia',
    ),
    Emoji(
      'ðŸ‡²ðŸ‡´',
      'Flag: Macau Sar China',
    ),
    Emoji(
      'ðŸ‡²ðŸ‡µ',
      'Flag: Northern Mariana Islands',
    ),
    Emoji(
      'ðŸ‡²ðŸ‡¶',
      'Flag: Martinique',
    ),
    Emoji(
      'ðŸ‡²ðŸ‡·',
      'Flag: Mauritania',
    ),
    Emoji(
      'ðŸ‡²ðŸ‡¸',
      'Flag: Montserrat',
    ),
    Emoji(
      'ðŸ‡²ðŸ‡¹',
      'Flag: Malta',
    ),
    Emoji(
      'ðŸ‡²ðŸ‡º',
      'Flag: Mauritius',
    ),
    Emoji(
      'ðŸ‡²ðŸ‡»',
      'Flag: Maldives',
    ),
    Emoji(
      'ðŸ‡²ðŸ‡¼',
      'Flag: Malawi',
    ),
    Emoji(
      'ðŸ‡²ðŸ‡½',
      'Flag: Mexico',
    ),
    Emoji(
      'ðŸ‡²ðŸ‡¾',
      'Flag: Malaysia',
    ),
    Emoji(
      'ðŸ‡²ðŸ‡¿',
      'Flag: Mozambique',
    ),
    Emoji(
      'ðŸ‡³ðŸ‡¦',
      'Flag: Namibia',
    ),
    Emoji(
      'ðŸ‡³ðŸ‡¨',
      'Flag: New Caledonia',
    ),
    Emoji(
      'ðŸ‡³ðŸ‡ª',
      'Flag: Niger',
    ),
    Emoji(
      'ðŸ‡³ðŸ‡«',
      'Flag: Norfolk Island',
    ),
    Emoji(
      'ðŸ‡³ðŸ‡¬',
      'Flag: Nigeria',
    ),
    Emoji(
      'ðŸ‡³ðŸ‡®',
      'Flag: Nicaragua',
    ),
    Emoji(
      'ðŸ‡³ðŸ‡±',
      'Flag: Netherlands',
    ),
    Emoji(
      'ðŸ‡³ðŸ‡´',
      'Flag: Norway',
    ),
    Emoji(
      'ðŸ‡³ðŸ‡µ',
      'Flag: Nepal',
    ),
    Emoji(
      'ðŸ‡³ðŸ‡·',
      'Flag: Nauru',
    ),
    Emoji(
      'ðŸ‡³ðŸ‡º',
      'Flag: Niue',
    ),
    Emoji(
      'ðŸ‡³ðŸ‡¿',
      'Flag: New Zealand',
    ),
    Emoji(
      'ðŸ‡´ðŸ‡²',
      'Flag: Oman',
    ),
    Emoji(
      'ðŸ‡µðŸ‡¦',
      'Flag: Panama',
    ),
    Emoji(
      'ðŸ‡µðŸ‡ª',
      'Flag: Peru',
    ),
    Emoji(
      'ðŸ‡µðŸ‡«',
      'Flag: French Polynesia',
    ),
    Emoji(
      'ðŸ‡µðŸ‡¬',
      'Flag: Papua New Guinea',
    ),
    Emoji(
      'ðŸ‡µðŸ‡­',
      'Flag: Philippines',
    ),
    Emoji(
      'ðŸ‡µðŸ‡°',
      'Flag: Pakistan',
    ),
    Emoji(
      'ðŸ‡µðŸ‡±',
      'Flag: Poland',
    ),
    Emoji(
      'ðŸ‡µðŸ‡²',
      'Flag: St. Pierre & Miquelon',
    ),
    Emoji(
      'ðŸ‡µðŸ‡³',
      'Flag: Pitcairn Islands',
    ),
    Emoji(
      'ðŸ‡µðŸ‡·',
      'Flag: Puerto Rico',
    ),
    Emoji(
      'ðŸ‡µðŸ‡¸',
      'Flag: Palestinian Territories',
    ),
    Emoji(
      'ðŸ‡µðŸ‡¹',
      'Flag: Portugal',
    ),
    Emoji(
      'ðŸ‡µðŸ‡¼',
      'Flag: Palau',
    ),
    Emoji(
      'ðŸ‡µðŸ‡¾',
      'Flag: Paraguay',
    ),
    Emoji(
      'ðŸ‡¶ðŸ‡¦',
      'Flag: Qatar',
    ),
    Emoji(
      'ðŸ‡·ðŸ‡ª',
      'Flag: RÃ©union',
    ),
    Emoji(
      'ðŸ‡·ðŸ‡´',
      'Flag: Romania',
    ),
    Emoji(
      'ðŸ‡·ðŸ‡¸',
      'Flag: Serbia',
    ),
    Emoji(
      'ðŸ‡·ðŸ‡º',
      'Flag: Russia',
    ),
    Emoji(
      'ðŸ‡·ðŸ‡¼',
      'Flag: Rwanda',
    ),
    Emoji(
      'ðŸ‡¸ðŸ‡¦',
      'Flag: Saudi Arabia',
    ),
    Emoji(
      'ðŸ‡¸ðŸ‡§',
      'Flag: Solomon Islands',
    ),
    Emoji(
      'ðŸ‡¸ðŸ‡¨',
      'Flag: Seychelles',
    ),
    Emoji(
      'ðŸ‡¸ðŸ‡©',
      'Flag: Sudan',
    ),
    Emoji(
      'ðŸ‡¸ðŸ‡ª',
      'Flag: Sweden',
    ),
    Emoji(
      'ðŸ‡¸ðŸ‡¬',
      'Flag: Singapore',
    ),
    Emoji(
      'ðŸ‡¸ðŸ‡­',
      'Flag: St. Helena',
    ),
    Emoji(
      'ðŸ‡¸ðŸ‡®',
      'Flag: Slovenia',
    ),
    Emoji(
      'ðŸ‡¸ðŸ‡¯',
      'Flag: Svalbard & Jan Mayen',
    ),
    Emoji(
      'ðŸ‡¸ðŸ‡°',
      'Flag: Slovakia',
    ),
    Emoji(
      'ðŸ‡¸ðŸ‡±',
      'Flag: Sierra Leone',
    ),
    Emoji(
      'ðŸ‡¸ðŸ‡²',
      'Flag: San Marino',
    ),
    Emoji(
      'ðŸ‡¸ðŸ‡³',
      'Flag: Senegal',
    ),
    Emoji(
      'ðŸ‡¸ðŸ‡´',
      'Flag: Somalia',
    ),
    Emoji(
      'ðŸ‡¸ðŸ‡·',
      'Flag: Suriname',
    ),
    Emoji(
      'ðŸ‡¸ðŸ‡¸',
      'Flag: South Sudan',
    ),
    Emoji(
      'ðŸ‡¸ðŸ‡¹',
      'Flag: SÃ£o TomÃ© & PrÃ­ncipe',
    ),
    Emoji(
      'ðŸ‡¸ðŸ‡»',
      'Flag: El Salvador',
    ),
    Emoji(
      'ðŸ‡¸ðŸ‡½',
      'Flag: Sint Maarten',
    ),
    Emoji(
      'ðŸ‡¸ðŸ‡¾',
      'Flag: Syria',
    ),
    Emoji(
      'ðŸ‡¸ðŸ‡¿',
      'Flag: Swaziland',
    ),
    Emoji(
      'ðŸ‡¹ðŸ‡¦',
      'Flag: Tristan Da Cunha',
    ),
    Emoji(
      'ðŸ‡¹ðŸ‡¨',
      'Flag: Turks & Caicos Islands',
    ),
    Emoji(
      'ðŸ‡¹ðŸ‡©',
      'Flag: Chad',
    ),
    Emoji(
      'ðŸ‡¹ðŸ‡«',
      'Flag: French Southern Territories',
    ),
    Emoji(
      'ðŸ‡¹ðŸ‡¬',
      'Flag: Togo',
    ),
    Emoji(
      'ðŸ‡¹ðŸ‡­',
      'Flag: Thailand',
    ),
    Emoji(
      'ðŸ‡¹ðŸ‡¯',
      'Flag: Tajikistan',
    ),
    Emoji(
      'ðŸ‡¹ðŸ‡°',
      'Flag: Tokelau',
    ),
    Emoji(
      'ðŸ‡¹ðŸ‡±',
      'Flag: Timor-Leste',
    ),
    Emoji(
      'ðŸ‡¹ðŸ‡²',
      'Flag: Turkmenistan',
    ),
    Emoji(
      'ðŸ‡¹ðŸ‡³',
      'Flag: Tunisia',
    ),
    Emoji(
      'ðŸ‡¹ðŸ‡´',
      'Flag: Tonga',
    ),
    Emoji(
      'ðŸ‡¹ðŸ‡·',
      'Flag: Turkey',
    ),
    Emoji(
      'ðŸ‡¹ðŸ‡¹',
      'Flag: Trinidad & Tobago',
    ),
    Emoji(
      'ðŸ‡¹ðŸ‡»',
      'Flag: Tuvalu',
    ),
    Emoji(
      'ðŸ‡¹ðŸ‡¼',
      'Flag: Taiwan',
    ),
    Emoji(
      'ðŸ‡¹ðŸ‡¿',
      'Flag: Tanzania',
    ),
    Emoji(
      'ðŸ‡ºðŸ‡¦',
      'Flag: Ukraine',
    ),
    Emoji(
      'ðŸ‡ºðŸ‡¬',
      'Flag: Uganda',
    ),
    Emoji(
      'ðŸ‡ºðŸ‡²',
      'Flag: U.S. Outlying Islands',
    ),
    Emoji(
      'ðŸ‡ºðŸ‡³',
      'Flag: United Nations',
    ),
    Emoji(
      'ðŸ‡ºðŸ‡¸',
      'Flag: United States',
    ),
    Emoji(
      'ðŸ‡ºðŸ‡¾',
      'Flag: Uruguay',
    ),
    Emoji(
      'ðŸ‡ºðŸ‡¿',
      'Flag: Uzbekistan',
    ),
    Emoji(
      'ðŸ‡»ðŸ‡¦',
      'Flag: Vatican City',
    ),
    Emoji(
      'ðŸ‡»ðŸ‡¨',
      'Flag: St. Vincent & Grenadines',
    ),
    Emoji(
      'ðŸ‡»ðŸ‡ª',
      'Flag: Venezuela',
    ),
    Emoji(
      'ðŸ‡»ðŸ‡¬',
      'Flag: British Virgin Islands',
    ),
    Emoji(
      'ðŸ‡»ðŸ‡®',
      'Flag: U.S. Virgin Islands',
    ),
    Emoji(
      'ðŸ‡»ðŸ‡³',
      'Flag: Vietnam',
    ),
    Emoji(
      'ðŸ‡»ðŸ‡º',
      'Flag: Vanuatu',
    ),
    Emoji(
      'ðŸ‡¼ðŸ‡«',
      'Flag: Wallis & Futuna',
    ),
    Emoji(
      'ðŸ‡¼ðŸ‡¸',
      'Flag: Samoa',
    ),
    Emoji(
      'ðŸ‡½ðŸ‡°',
      'Flag: Kosovo',
    ),
    Emoji(
      'ðŸ‡¾ðŸ‡ª',
      'Flag: Yemen',
    ),
    Emoji(
      'ðŸ‡¾ðŸ‡¹',
      'Flag: Mayotte',
    ),
    Emoji(
      'ðŸ‡¿ðŸ‡¦',
      'Flag: South Africa',
    ),
    Emoji(
      'ðŸ‡¿ðŸ‡²',
      'Flag: Zambia',
    ),
    Emoji(
      'ðŸ‡¿ðŸ‡¼',
      'Flag: Zimbabwe',
    ),
  ]),
];
