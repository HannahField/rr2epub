using Cascadia, Gumbo, HTTP

struct Chapter
    chapter_number::AbstractString
    chapter_url::AbstractString
    chapter_body::AbstractString
    chapter_title::AbstractString
    next_chapter_url::Union{AbstractString,Nothing}
end

function create_chapter(url::AbstractString)::Chapter
    r = HTTP.get(url)
    h = parsehtml(String(r.body))
    chapter_body = join(nodeText.(children(eachmatch(Selector(".chapter-inner"), h.root)[1])), "\r\n\r\n")
    chapter_body = replace(chapter_body,r"~~+" => "")
    chapter_number = split(split(url, "/")[end], "-")[2]
    chapter_title = join(upper_case_first_letter.(split(split(url, "/")[end], "-")[3:end]), " ")
    next_path = get(eachmatch(Selector(".btn-primary.col-xs-12"), h.root)[2].attributes, "href", nothing)
    next_url = isnothing(next_path) ? nothing : "https://www.royalroad.com" * next_path

    return Chapter(chapter_number, url, chapter_body, chapter_title, next_url)
end

upper_case_first_letter(s::AbstractString) = String([i == 1 ? uppercase(c) : c for (i, c) in enumerate(s)])


function Base.iterate(chap::Chapter, _)
    if (isnothing(chap.next_chapter_url))
        return nothing
    end
    return (create_chapter(chap.next_chapter_url), chap)
end

Base.IteratorSize(::Chapter) = Base.SizeUnknown()

get_next_chapter(chapter::Chapter) = isnothing(chapter.next_chapter_url) ? nothing : create_chapter(chapter.next_chapter_url)

chapters = Chapter[]

current_url = "https://www.royalroad.com/fiction/54915/a-guide-to-becoming-a-pirate-queen/chapter/1192437/operative-1-jailbreak"

current_chapter = create_chapter(current_url)

push!(chapters, current_chapter)

while (true)
    global current_url = current_chapter.next_chapter_url
    if isnothing(current_url)
        break
    end
    global current_chapter = create_chapter(current_url)
    push!(chapters,current_chapter)
    println(current_chapter.chapter_number)
end

function chapter_to_markdown(chapter,file)
    header = "# " * chapter.chapter_number * ": " * chapter.chapter_title
    write(file,header)
    write(file,"\r\n\r\n")
    write(file,chapter.chapter_body)
    write(file,"\r\n\r\n")
end

book = open("Operative.txt","w")
chapter_to_markdown.(chapters[1:50],book)
close(book)