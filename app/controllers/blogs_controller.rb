# frozen_string_literal: true

class BlogsController < ApplicationController
  include ActionView::Helpers::SanitizeHelper

  skip_before_action :authenticate_user!, only: %i[index show]

  before_action :set_blog, only: %i[show]
  before_action :set_current_user_blog, only: %i[edit update destroy]
  before_action :sanitize_blog_content, only: %i[create update]

  def index
    @blogs = Blog.search(params[:term]).published.default_order
  end

  def show
    return if !@blog.secret? || @blog.user == current_user

    redirect_to blogs_url, alert: 'Blog not found.'
  end

  def new
    @blog = Blog.new
  end

  def edit; end

  def create
    @blog = current_user.blogs.new(blog_params)

    if @blog.save
      redirect_to blog_url(@blog), notice: 'Blog was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @blog.update(blog_params)
      redirect_to blog_url(@blog), notice: 'Blog was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @blog.destroy!

    redirect_to blogs_url, notice: 'Blog was successfully destroyed.', status: :see_other
  end

  private

  def set_blog
    @blog = Blog.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to blogs_url, alert: 'Blog not found.'
  end

  def set_current_user_blog
    @blog = current_user.blogs.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to blog_url(params[:id]), alert: 'Permission denied for this blog.'
  end

  def sanitize_blog_content
    tags = %w[a acronym b strong i em li ul ol h1 h2 h3 h4 h5 h6 blockquote br cite sub sup ins p]
    blog_params[:content] = sanitize(blog_params[:content], tags:, attributes: %w[href title])
  end

  def blog_params
    params.require(:blog).permit(:title, :content, :secret, :random_eyecatch)
  end
end
