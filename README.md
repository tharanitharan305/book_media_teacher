# book_media_teacher

tharanitharan's new Flutter project.

## Getting Started

In this project we can create a book with multiple pages with multiple canvas like text, audio, video and image , edit their positions and size , preview it and export into a json file

Packages used:
supabase (to store the videos, images and audios),
uuid (to create unique id for canvas that are stored in supabase)
flutter_colorpicker (to select color for the canvas)
flutter_layout_grid (to align grids in textbook pages)
audio_player (to play audio via network(public supabase) links)
path_provider (to store the json file in local)
draggable_widget (to make the canvas widgets dragable)
flutter_bloc and equatable (used for state management completly eleminating setstate)
video_player_win (to play videos in windows app)
file_picker (to pic files like video image and audio localy)

Project Flow
Initally i hae done supabase setup, repo providers and bloc providers in the main, using MyApp class i have navogated to EditorPage, in EditorPage I create a page named page-1 initaly and load the tools in the left side and the page preview in the right and centered the pagelist using  row and then from the tools bar iam selecting weather a image or text or audio or video if they are audio / video/image user supabase services iam storing them in the supabase bucket there we need a authenticated user so using a dummy user test and then adding the asset to the book-media bucket with a unoque name using uuid and then getting its public link  and changing the state and the page gets a widget and the widget will have a type and using that we display them like "image" "video"  then in preview that pagemodel list os previewed and while export the json will have the raw text and for media it will hve the public url then the json is stored with custom name in local 
Canvas Properties:
Text: we can position center top right, bottom left esc , delete, size change , color change, dragable,bold, italic, underline, stack front , stack back
other canvas :  we can position center top right, bottom left esc , delete, size change , dragable, stack front , stack back

demo video link :https://drive.google.com/file/d/1rlk_azSy1enL9WwFA-3nF2IGzq52GLLO/view?usp=sharing

