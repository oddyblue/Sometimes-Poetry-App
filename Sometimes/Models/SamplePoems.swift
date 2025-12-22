// SamplePoems.swift
// Fallback data when JSON is missing

import Foundation

struct SamplePoems {
    static let all: [Poem] = [
        Poem(
            id: "frost-stopping-by-woods",
            title: "Stopping by Woods on a Snowy Evening",
            poet: "Robert Frost",
            text: """
            Whose woods these are I think I know.   
            His house is in the village though;   
            He will not see me stopping here   
            To watch his woods fill up with snow.   
            
            My little horse must think it queer   
            To stop without a farmhouse near   
            Between the woods and frozen lake   
            The darkest evening of the year.   
            
            He gives his harness bells a shake   
            To ask if there is some mistake.   
            The only other sound's the sweep   
            Of easy wind and downy flake.   
            
            The woods are lovely, dark and deep,   
            But I have promises to keep,   
            And miles to go before I sleep,   
            And miles to go before I sleep.
            """,
            year: 1923,
            context: PoemContext(
                timeOfDay: ["evening", "night"],
                seasons: ["winter"],
                weather: ["snowy", "cloudy", "any"],
                mood: ["contemplative", "peaceful", "solitary"],
                specialDates: ["winter_solstice"],
                days: nil
            ),
            meta: PoemMeta(
                length: "medium",
                lines: 16,
                difficulty: "accessible"
            )
        ),
        
        Poem(
            id: "hardy-darkling-thrush",
            title: "The Darkling Thrush",
            poet: "Thomas Hardy",
            text: """
            I leant upon a coppice gate
            When Frost was spectre-grey,
            And Winter's dregs made desolate
            The weakening eye of day.
            The tangled bine-stems scored the sky
            Like strings of broken lyres,
            And all mankind that haunted nigh
            Had sought their household fires.
            
            The land's sharp features seemed to be
            The Century's corpse outleant,
            His crypt the cloudy canopy,
            The wind his death-lament.
            The ancient pulse of germ and birth
            Was shrunken hard and dry,
            And every spirit upon earth
            Seemed fervourless as I.
            
            At once a voice arose among
            The bleak twigs overhead
               In a full-hearted evensong
            Of joy illimited;
            An aged thrush, frail, gaunt, and small,
            In blast-beruffled plume,
            Had chosen thus to fling his soul
            Upon the growing gloom.
            
            So little cause for carolings
            Of such ecstatic sound
            Was written on terrestrial things
            Afar or around;
            That I could think there trembled through
            His happy good-night air
            Some blessed Hope, whereof he knew
            And I was unaware.
            """,
            year: 1900,
            context: PoemContext(
                timeOfDay: ["afternoon", "evening"],
                seasons: ["winter"],
                weather: ["cloudy", "foggy", "any"],
                mood: ["melancholic", "hopeful"],
                specialDates: ["new_year"],
                days: nil
            ),
            meta: PoemMeta(
                length: "long",
                lines: 32,
                difficulty: "medium"
            )
        ),
        
        Poem(
            id: "dickinson-hope",
            title: "\"Hope\" is the thing with feathers",
            poet: "Emily Dickinson",
            text: """
            "Hope" is the thing with feathers -
            That perches in the soul -
            And sings the tune without the words -
            And never stops - at all -
            
            And sweetest - in the Gale - is heard -
            And sore must be the storm -
            That could abash the little Bird -
            That kept so many warm -
            
            I've heard it in the chillest land -
            And on the strangest Sea -
            Yet - never - in Extremity,
            It asked a crumb - of me.
            """,
            year: 1891,
            publicDomain: true,
            context: PoemContext(
                timeOfDay: nil,
                seasons: nil,
                weather: ["stormy", "rainy", "any"],
                mood: ["hopeful", "resilient"],
                specialDates: nil,
                days: nil
            ),
            meta: PoemMeta(
                length: "short",
                lines: 12,
                difficulty: "accessible"
            )
        ),
        
        Poem(
            id: "wordsworth-daffodils",
            title: "I Wandered Lonely as a Cloud",
            poet: "William Wordsworth",
            text: """
            I wandered lonely as a cloud
            That floats on high o'er vales and hills,
            When all at once I saw a crowd,
            A host, of golden daffodils;
            Beside the lake, beneath the trees,
            Fluttering and dancing in the breeze.
            
            Continuous as the stars that shine
            And twinkle on the milky way,
            They stretched in never-ending line
            Along the margin of a bay:
            Ten thousand saw I at a glance,
            Tossing their heads in sprightly dance.
            
            The waves beside them danced; but they
            Out-did the sparkling waves in glee:
            A poet could not but be gay,
            In such a jocund company:
            I gazed—and gazed—but little thought
            What wealth the show to me had brought:
            
            For oft, when on my couch I lie
            In vacant or in pensive mood,
            They flash upon that inward eye
            Which is the bliss of solitude;
            And then my heart with pleasure fills,
            And dances with the daffodils.
            """,
            year: 1807,
            publicDomain: true,
            context: PoemContext(
                timeOfDay: ["morning", "afternoon"],
                seasons: ["spring"],
                weather: ["clear", "cloudy", "any"],
                mood: ["cheerful", "peaceful"],
                specialDates: ["spring_equinox"],
                days: nil
            ),
            meta: PoemMeta(
                length: "medium",
                lines: 24,
                difficulty: "accessible"
            )
        )
    ]
}
