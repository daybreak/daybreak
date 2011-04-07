# Page Origin

Ever create a page and forget what the parent page was? This extension fixes that problem rather gracefully. When you go to create or edit a page, you will now see the parent page title right under the page title text field.

**UPDATE** With a little inspiration from the made_easy extension from spanner, I made the display of the parent page even more useful. Instead of just the parent page name, it displays the full url. You see the url page slug change as you edit the page title.

`http://yourradiantinstall.com/blog/2009/10/02/you-blog-post-here`

## Installation

    $ git clone git://github.com/atinypixel/radiant-page-origin-extension.git vendor/extensions/page_origin
    $ rake radiant:extensions:page_origin:update
    
or

    $ rake ray:i name=page-origin hub=atinypixel
    


