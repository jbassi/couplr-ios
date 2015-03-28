## Description

    Couplr allows you to anonymously match your friends together in hypothetical romantic pairings for dynamically updated titles such as "One night stand" and "One true pairing". Check out popular matches from around your network, and see who your friends have matched you with. Every match you vote for is anonymous, and our app stores no personal information. Couplr will never post on your Facebook.

## What to test

    * The match view
        * A 3x3 grid of Facebook profile images should appear upon loading
        * Pressing each profile image should select that user
        * Pressing "Submit" should reload the title and grid and deselect users
        * If fewer than 2 friends are selected, pressing "Submit" should do nothing
        * The user may not select more than 2 friends
        * Pressing "Reset" should refresh the grid
        * Pressing "Names" should display names over profile pictures
        * Pressing the title at the top should allow the user to select a new title
    * The profile view
        * A list of titles should appear, with the number of times the user has been voted for that title
        * Pressing each title should pop out a new table showing the people the user has been voted with
            * Each row should show the profile picture of the friend and the number of votes with that friend
        * Pressing "Recent matches" should pop out a table showing recent matches
            * Each row should show the profile picture and title of the friend the user was matched with
    * The newsfeed view
        * A table should display recent matches around your network
        * The time since that match was submitted should show below the title
        * The profile pictures of the matched pair should show side by side
        * Pressing "Names" should display names over the profile pictures
